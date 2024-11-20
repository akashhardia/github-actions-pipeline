# frozen_string_literal: true

# 決済処理
# MIXI Mに繋がっていたものを新会員基盤の決済APIに繋ぎ変えました
class PaymentTransactor

  # 新会員基盤のURL
  BASE_URL = "#{Rails.application.credentials.new_system[:base_url]}"
  # 新会員基盤に認可代わりに飛ばすリファラ
  REFERER = "#{Rails.application.credentials.new_system[:referer]}"

  # エラーを起こすとユーザーがバックエンドの方に取り残されるため、raiseではなくsucceed: error:で返すこと
  class << self

    # 決済リクエスト（新会員基盤に決済情報を飛ばし、フロントを新会員基盤に飛ばす）
    # charge_idとintegration_uuidは基本的に同じものを指している
    # （integration_uuidはMIXI Mの切り離し後のcharge_idの代替物であり、新会員基盤との決済情報連携用のキーでもある）
    def request(user)
      # 購入したい座席などの情報
      cart = Cart.new(user)

      error = order_validation(cart)
      return { error: error.to_s } if error.present?

      # 決済処理に必要な各種情報
      purchase_order = cart.purchase_order
      user = cart.user
      orders = cart.orders[:orders]
      coupon_id = cart.orders[:coupon_id]
      campaign_code = cart.orders[:campaign_code]

      total_price = purchase_order.total_price
      products = purchase_order.product_list

      ActiveRecord::Base.transaction do
        # 選んだチケットに基づき予約チケット情報の作成（チケットは事前に生成されており、購入者に結び付けていく方式）
        ticket_reserves = orders.map do |order|
          TicketReserve.new(ticket_id: order[:ticket_id], seat_type_option_id: order[:option_id])
        end

        # 新会員基盤に飛ばす決済情報と座席情報と開催情報（座席情報と開催情報は新会員基盤のフロントで見せるため）
        body = {
          # 決済情報（金額など）
          main: {
            user_id: user.id,
            subtotal_amount: purchase_order.subtotal_price,
            campaign_discount: purchase_order.campaign_total_discount_amount,
            coupon_discount: purchase_order.coupon_discount_amount,
            option_discount: purchase_order.option_discount_amount,
            total_amount: purchase_order.total_price,
          },
          # 座席情報
          seats_info: cart.tickets.map { | ticket |
            {
              area: ticket.area_name,
              type: ticket.position,
              row: ticket.row,
              num: ticket.seat_number
            }
          },
          # 開催情報
          hold_info: {
            date: cart.hold_daily_schedule.hold_daily.event_date,
            day_or_night: cart.hold_daily_schedule.day_night_display,
            open_venue_time: cart.hold_daily_schedule.opening_display,
            start_show_time: cart.hold_daily_schedule.start_display,
            season: (cart.hold_daily_schedule.promoter_year.to_s[-2..-1]) + "-" + ((cart.hold_daily_schedule.promoter_year + 1).to_s[-2..-1]) + " " + season_name_of(cart.hold_daily_schedule.period),
            round: round_name_of(cart.hold_daily_schedule.round),
            game_type: event_name_of(cart.hold_daily_schedule.high_priority_event_code)
          }
        }

        # 新会員基盤の決済リクエスト呼び出し
        # サービスに切り出しておらず申し訳ありません
        api_response = HTTParty.post(BASE_URL + "/payment/request_order", headers: { "Content-Type": "application/json", "Referer": REFERER },  body: body.to_json())
        api_response_body = JSON.parse(api_response.body)

        result = { get_url: BASE_URL + "/payment/menu", charge_id: api_response_body['integration_uuid'] }

        # こちら側の決済情報をDBに登録
        # クーポン情報取得
        user_coupon = user.user_coupons.find_by(coupon_id: coupon_id)
        # 支払い情報登録
        payment = Payment.new(charge_id: result[:charge_id], payment_progress: :requesting_payment)
        # 注文情報登録
        order = Order.new(user: user, payment: payment, order_at: Time.zone.now, order_type: :purchase, user_coupon: user_coupon,
                          total_price: total_price, seat_sale: cart.seat_sale, coupon_discount: purchase_order.coupon_discount_amount,
                          option_discount: purchase_order.option_discount_amount, campaign_discount: purchase_order.campaign_total_discount_amount)
        order.ticket_reserves << ticket_reserves

        campaign = Campaign.find_by(code: campaign_code)
        order.campaign_usage = CampaignUsage.new(campaign: campaign) if campaign

        # commit
        order.save!

        # integration_uuidとorder_idのmapを作る
        redis = Redis.current
        redis.set(result[:charge_id], order.id)
        redis.expire(result[:charge_id], 1.day)

        cart.tickets.each do |ticket|
          ticket.extend_ownership_ttl(Cart::CART_EXPIRATION)
        end
        cart.ticket_orders.expire(Cart::CART_EXPIRATION)

        { redirect: result[:get_url], charge_id: result[:charge_id] }
      end
    end

    # 決済手続き完了後処理
    def request_completed(user, charge_id)
      payment = Payment.find_by!(charge_id: charge_id)
      cart = Cart.new(user)
      order = Order.includes(:tickets).find(payment.order_id)
      tickets = order.tickets
      total_price = order.total_price
      decision = 'request_completed'
      error = order_validation(cart, decision) || check_order_integrity(cart, order)
      # 注文情報の整合性チェック？
      raise FatalSixgramPaymentError if error.present?

      ActiveRecord::Base.transaction do
        payment.waiting_capture!
        tickets.each { |ticket| ticket.update!(user_id: user.id, status: :temporary_hold) }
      end

      # 支払確定（座席紐づけなどを行う）
      capture(user, cart, tickets, payment, total_price)

    rescue FatalSixgramPaymentError => e
      Rails.logger.fatal e.message
      error_operation(tickets, payment, user)

      raise e
    rescue CustomError => e
      Rails.logger.info e.message
      error_operation(tickets, payment, user)

      { error: e.code }
    rescue StandardError => e
      Rails.logger.error e.message
      error_operation(tickets, payment, user)

      raise e
    end

    # taskdo補足
    # 返金処理
    # 管理画面側からの返金処理と思われる
    def refund(order_id)
      order = Order.includes(:tickets, :payment).find(order_id)
      ActiveRecord::Base.transaction do
        # ユーザーとチケットの紐付けを外す
        order.payment.update!(refunded_at: Time.zone.now, payment_progress: :refunded)
        order.update!(returned_at: Time.zone.now)
        # チケットのステータスを販売停止にする
        order.tickets.each { |ticket| ticket.update!(user: nil, qr_ticket_id: nil, status: :not_for_sale, purchase_ticket_reserve_id: nil, current_ticket_reserve_id: nil) }

        # 返金APIで返金処理をする
        # result = SixgramPayment::Service.refund(order.payment.charge_id)
        result = NewSystem::Service.refund(order.payment.charge_id)
        unless result[:ok?]
          Rails.logger.info '新会員基盤側の返金処理でエラーが発生しました。詳細は新会員基盤のログを参照してください。charge_id = ' + order.payment.charge_id
          raise '新会員基盤側の返金処理でエラーが発生しました。詳細は新会員基盤のログを参照してください。charge_id = ' + order.payment.charge_id
        end
      end
    rescue StandardError => e
      Rails.logger.info e.message

      raise e
    end

    private

    # taskdo 補足
    # 【支払い確定】
    # request_completedから呼ばれる。
    # 外からは呼ばれない。
    # 支払確定
    def capture(user, cart, tickets, payment, total_price)

      # 支払確定が確認できたので、座席紐付け処理
      ActiveRecord::Base.transaction do
        payment.update!(captured_at: Time.zone.now, payment_progress: :captured)
        payment.order.ticket_reserves.each do |ticket_reserve|
          ticket_reserve.ticket.update!(user: user, qr_ticket_id: AdmissionUuid.generate_uuid, status: :sold, purchase_ticket_reserve_id: ticket_reserve.id, current_ticket_reserve_id: ticket_reserve.id)
        end
      end

      ActiveRecord::Base.transaction do
        NotificationMailer.send_purchase_completion_notification_to_user(user, tickets.to_a, total_price).deliver_later
      end

      # カートの開放
      cart.clear_hold_tickets

      {}
    end

    def check_order_integrity(cart, order)
      ticket_reserves = order.ticket_reserves

      return :invalid_order if order.user_coupon.present? && cart.orders[:coupon_id] != order.user_coupon.coupon_id

      return :invalid_order unless cart.orders[:orders].size == ticket_reserves.size

      result = cart.orders[:orders].all? do |cart_order|
        ticket_id = cart_order[:ticket_id]
        option_id = cart_order[:option_id]
        ticket_reserves.find { |tr| tr.ticket_id == ticket_id && tr.seat_type_option_id == option_id }
      end

      :invalid_order unless result
    end

    def order_validation(cart, decision = nil)
      return :no_order if cart.orders.blank?
      return :ownership_error unless cart.recheck_ownership(Cart::CART_EXPIRATION)

      validator = OrderValidator.new(cart.orders[:orders], cart.orders[:coupon_id], cart.orders[:campaign_code], cart.user, decision)
      validator.validation_error
    end

    # 販売用返金
    def sales_refund(payment)
      # 座席紐付けに失敗した場合、返金APIを実行
      NewSystem::Service.refund(payment.charge_id)
      # orderの返金日時を登録
      payment.order.update!(returned_at: Time.zone.now)
      payment.update!(refunded_at: Time.zone.now)
    end

    # 決済エラー時の処理
    def error_operation(tickets, payment, user)
      payment.failed_capture!
      tickets.each { |ticket| ticket.update!(user: nil, status: :available) if ticket.temporary_hold? && ticket.user_id == user.id }
      # 返金処理
      sales_refund(payment)
    end

    # 従来はフロントで完結していましたが、新会員基盤に情報がないため、
    # こちらから渡す必要があり、とりあえずベタ書きで対応した次第です。
    # ラウンド数追加などがあった場合はこちらも修正してください。
    def season_name_of(key)
      Hash.new("").merge({
        "spring" => "スプリングシーズン",
        "summer" => "サマーシーズン",
        "autumn" => "オータムシーズン",
        "winter" => "ウィンターシーズン",
        "wildcard" => "ワイルドカード",
        "final" => "年間ファイナル",
        "period1" => "ジャパンヒーローズ",
        "period2" => "シーズンゼロ",
        "quarter1" => "ファーストクォーター",
        "quarter2:" => "セカンドクォーター",
        "quarter3" => "サードクォーター",
        "quarter4" => "フォースクォーター",
        "spring_s" => "スプリングステージ",
        "summer_s" => "サマーステージ",
        "autumn_s" => "オータムステージ",
        "winter_s" => "ウィンターステージ",
      })[key]
    end

    def round_name_of(key)
      Hash.new("").merge({
        1 => "ラウンド1",
        2 => "ラウンド2",
        3 => "ラウンド3",
        4 => "ラウンド4",
        5 => "ラウンド5",
        6 => "ラウンド6",
        7 => "ラウンド7",
        8 => "ラウンド8",
        9 => "ラウンド9",
        10=> "ラウンド10",
        11=> "ラウンド11",
        12=> "ラウンド12",
        13=> "ラウンド13",
        14=> "ラウンド14",
        15=> "ラウンド15",
        16=> "ラウンド16",
        17=> "ラウンド17",
        18=> "ラウンド18",
        19=> "ラウンド19",
        20=> "ラウンド20",
        21=> "ラウンド21",
        22=> "ラウンド22",
        23=> "ラウンド23",
        24=> "ラウンド24",
        25=> "ラウンド25",
        26=> "ラウンド26",
        27=> "ラウンド27",
        28=> "ラウンド28",
        29=> "ラウンド29",
        30=> "ラウンド30",
        31=> "ラウンド31",
        32=> "ラウンド32",
        33=> "ラウンド33",
        34=> "ラウンド34",
        35=> "ラウンド35",
        36=> "ラウンド36",
        37=> "ラウンド37",
        38=> "ラウンド38",
        39=> "ラウンド39",
        40=> "ラウンド40",
        41=> "ラウンド41",
        42=> "ラウンド42",
        43=> "ラウンド43",
        44=> "ラウンド44",
        45=> "ラウンド45",
        46=> "ラウンド46",
        47=> "ラウンド47",
        48=> "ラウンド48",
        49=> "ラウンド49",
        50=> "ラウンド50",
        101=> "スペシャルマッチ1",
        102=> "スペシャルマッチ2",
        103=> "スペシャルマッチ3",
        104=> "スペシャルマッチ4",
        105=> "スペシャルマッチ5",
        106=> "スペシャルマッチ6",
        107=> "スペシャルマッチ7",
        108=> "スペシャルマッチ8",
        109=> "スペシャルマッチ9",
        110=> "スペシャルマッチ10",
        111=> "スペシャルマッチ11",
        131=> "PIST6カップ1",
        132=> "PIST6カップ2",
        133=> "PIST6カップ3",
        134=> "PIST6カップ4",
        135=> "PIST6カップ5",
        136=> "PIST6カップ6",
        137=> "PIST6カップ7",
        138=> "PIST6カップ8",
        139=> "PIST6カップ9",
        201=> "設定なし",
        301=> "シーズンファイナル",
        302=> "ファイナルラウンド",
        303=> "U35バトル",
        304=> "年間ファイナル",
        401=> "4月 第1戦",
        402=> "4月 第2戦",
        403=> "4月 第3戦",
        404=> "4月 第4戦",
        405=> "4月 第5戦",
        411=> "5月 第1戦",
        412=> "5月 第2戦",
        413=> "5月 第3戦",
        414=> "5月 第4戦",
        415=> "5月 第5戦",
        421=> "6月 第1戦",
        422=> "6月 第2戦",
        423=> "6月 第3戦",
        424=> "6月 第4戦",
        425=> "6月 第5戦",
        431=> "7月 第1戦",
        432=> "7月 第2戦",
        433=> "7月 第3戦",
        434=> "7月 第4戦",
        435=> "7月 第5戦",
        441=> "8月 第1戦",
        442=> "8月 第2戦",
        443=> "8月 第3戦",
        444=> "8月 第4戦",
        445=> "8月 第5戦",
        451=> "9月 第1戦",
        452=> "9月 第2戦",
        453=> "9月 第3戦",
        454=> "9月 第4戦",
        455=> "9月 第5戦",
        461=> "10月 第1戦",
        462=> "10月 第2戦",
        463=> "10月 第3戦",
        464=> "10月 第4戦",
        465=> "10月 第5戦",
        471=> "11月 第1戦",
        472=> "11月 第2戦",
        473=> "11月 第3戦",
        474=> "11月 第4戦",
        475=> "11月 第5戦",
        481=> "12月 第1戦",
        482=> "12月 第2戦",
        483=> "12月 第3戦",
        484=> "12月 第4戦",
        485=> "12月 第5戦",
        491=> "1月 第1戦",
        492=> "1月 第2戦",
        493=> "1月 第3戦",
        494=> "1月 第4戦",
        495=> "1月 第5戦",
        501=> "2月 第1戦",
        502=> "2月 第2戦",
        503=> "2月 第3戦",
        504=> "2月 第4戦",
        505=> "2月 第5戦",
        511=> "3月 第1戦",
        512=> "3月 第2戦",
        513=> "3月 第3戦",
        514=> "3月 第4戦",
        515=> "3月 第5戦",
      })[key]
    end

    def event_name_of(key)
      Hash.new("").merge({
         "2" => "準決勝",
         "3" => "決勝",
         "R" => "順位戦 1回戦",
         "T" => "順位決定戦",
         "U" => "1次予選",
         "V" => "2次予選",
         "W" => "W",
         "X" => "X",
         "Y" => "Y"
       })[key]
    end
  end
end

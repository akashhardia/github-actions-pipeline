# frozen_string_literal: true

module Sales
  # 申込コントローラ
  class OrdersController < ApplicationController
    before_action :ng_user_redirect, only: :pre_request
    skip_before_action :require_login!, only: [:capture2, :update_order_status_from_new_system, :capture_from_new_system]

    def index
      # 譲渡については購入履歴では表示しないので外す
      orders = current_user.orders
                           .includes(seat_sale: { hold_daily_schedule: [:races, { hold_daily: :hold }] })
                           .payment_captured_or_refunded
                           .page(params[:page] || 1).per(10).order('orders.id DESC')
      pagination = resources_with_pagination(orders)
      serialized_orders = ActiveModelSerializers::SerializableResource.new(orders, key_transform: :camel_lower)
      render json: { orders: serialized_orders, pagination: pagination }
    end

    def show
      order = current_user.orders.includes(ticket_reserves: :ticket).find(params[:id])
      render json: Serializers::OrderDetail.create(order), serializer: OrderDetailSerializer, key_transform: :camel_lower
    end
    def pre_request
      result = PaymentTransactor.request(current_user)
      # エラーがある場合は確認画面に戻す
      # return redirect_to "#{Rails.application.credentials.environmental[:sales_front_host_name]}/purchase/preview?error=#{result[:error]}", status: :moved_permanently if result[:error]
      return render json: { redirect_to: "#{Rails.application.credentials.environmental[:sales_front_host_name]}/purchase/preview?error=#{result[:error]}", integration_uuid: "" } if result[:error]
      # if result[:error] == 'no_order'
      #   return render json: { redirect_to: "#{Rails.application.credentials.new_system[:base_url]}" + "/payment/mpi/result", mErrMsg: "有効購入時間が過ぎております。お手数ですが、再度ご購入をお願いいたします"}
      # elsif result[:error]
      #   return render json: { redirect_to: "#{Rails.application.credentials.environmental[:sales_front_host_name]}/purchase/preview?error=#{result[:error]}", integration_uuid: "" }
      # end

      # 戻ってきたcharge_idをcartに保持
      cart = Cart.new(current_user)
      cart.replace_cart_charge_id(result[:charge_id])

      # redirect_to result[:redirect], status: :permanent_redirect, params: { 'integration_uuid': result[:integration_uuid] }
      render json: { redirect_to: result[:redirect], integration_uuid: result[:charge_id] }
    end
    def pre_request_redirect
      redirect_to params[:redirect_to], status: :permanent_redirect
    end

    # taskdo 補足
    #
    # 【☆廃止予定】
    #
    # 【決済手続き完了後処理】
    # DB操作：読、書
    # 決済手続きが正常に完了したか否かを取得する。
    # フロントではこれを用いてエラーの場合と完了の場合で画面遷移を分ける。
    def capture2
      cart = Cart.new(current_user)
      charge_id = cart.charge_id

      # charge_idがnilの場合はinternal_server_error
      raise StandardError if charge_id.nil?

      lock_key = "capture2_#{charge_id}"
      raise StandardError, I18n.t('custom_errors.orders.fail_to_purchase', charge_id: charge_id) unless Redis.current.setnx(lock_key, 1) # ロック作成と有無を確認 setnx(key, value) => Boolean

      Redis.current.expire(lock_key, 60) # デッドロック防止に期限つける（１分間）

      result = PaymentTransactor.request_completed(current_user, charge_id)

      return render json: { status: :ok, error: result[:error] } if result[:error]

      # charge_idを返す
      render json: { status: :ok, chargeId: charge_id }

      # 本来ならRedisのlockを解除する必要があるが、同じcharge_idは利用されない、ステージングでの検証をしやすくするという理由で解除を入れていません
    end

    def capture_from_new_system

      # 本システムのユーザーID。従来はセッションからユーザーを引いていたが、ブラウザではなく新会員基盤から叩くため、DBを引く必要がある。
      old_user_id = params[:old_user_id]
      this_system_user = User.find(old_user_id)

      cart = Cart.new(this_system_user)
      charge_id = cart.charge_id

      # charge_idがnilの場合はinternal_server_error
      raise StandardError if charge_id.nil?

      lock_key = "capture2_#{charge_id}"
      raise StandardError, I18n.t('custom_errors.orders.fail_to_purchase', charge_id: charge_id) unless Redis.current.setnx(lock_key, 1) # ロック作成と有無を確認 setnx(key, value) => Boolean

      Redis.current.expire(lock_key, 60) # デッドロック防止に期限つける（１分間）

      result = PaymentTransactor.request_completed(this_system_user, charge_id)

      return render json: { status: :ok, error: result[:error] } if result[:error]

      render json: { status: :ok }

      # 本来ならRedisのlockを解除する必要があるが、同じcharge_idは利用されない、ステージングでの検証をしやすくするという理由で解除を入れていません
    end

    # taskdo 補足
    # 【購入完了】
    # ☆廃止予定
    # DB操作：読
    # 指定した開催年度とシリーズに関するレースのデータを取得する。
    # 取得するレースには中止したレースなども含む。ラウンド数での絞り込みが可能。
    # 指定がない場合、最後にレース成立後に終了したレースが属するシーズンとシリーズをベースに取得する。
    # おそらく既に呼ばれないはずだが、削除を失念した。リリース前なので一旦そのままとする。
    def purchase_complete
      order_id = Payment.find_by(charge_id: params[:charge_id]).order_id
      return render json: {} unless Order.find(order_id).payment.captured?

      render json: {
        totalPrice: Order.find(order_id).total_price,
        transactionId: transaction_id(order_id),
        transactionProducts: transaction_products(order_id)
      }
    end

    # 新会員基盤から注文状態を更新する用
    def update_order_status_from_new_system
      integration_uuid = params[:integration_uuid]
      order_status = params[:order_status].to_i
    
      payment = Payment.find_by(charge_id: integration_uuid)
      return render json: { error: 'Payment not found' }, status: :not_found if payment.nil?
    
      order_id = payment.order_id
    
      Rails.logger.info "DEBUG @update_order_status_from_new_system: order_id is #{order_id}"
    
      order = Order.find(order_id)
      order.payment.update(payment_progress: order_status)

    
      Rails.logger.info "DEBUG @update_order_status_from_new_system: cart cleared. order_status is #{order_status}"
    
      if order_status == 1
        user_id = order.user_id
        user = User.find(user_id)
        cart = Cart.new(user)

        Rails.logger.info "orders_controller: 144 order_id is #{order_id}"
        Rails.logger.info "orders_controller: 145 order_status is #{order_status}"

        ActiveRecord::Base.transaction do
          order.ticket_reserves.each do |ticket_reserve|
            ticket_reserve.ticket.update!(status: :available)
          end
        end
        # カートの開放
        cart.clear_hold_tickets
      end

      Rails.logger.info "orders_controller: 156 order_id is #{order_id}"
      Rails.logger.info "orders_controller: 157 order_status is #{order_status}"

      render json: { status: :ok }
    end

    private

    def ng_user_redirect
      ng_user_check
    rescue StandardError
      redirect_to "#{Rails.application.credentials.environmental[:sales_front_host_name]}/login_error"
    end


    # ☆廃止予定からしか呼ばれていないため廃止予定
    # おそらく既に呼ばれないはずだが、削除を失念した。リリース前なので一旦そのままとする。
    def transaction_products(order_id)
      order = current_user.orders.find(order_id)
      tickets = order.tickets
      result = []

      if tickets.first.sales_type == 'unit'
        ticket = tickets.first
        result << transaction_products_ticket(order, ticket)
      else
        tickets.includes(:seat_area, :current_ticket_reserve, :seat_type).each do |one_ticket|
          result << transaction_products_ticket(order, one_ticket)
        end
      end
      result
    end

    # 廃止予定からしか呼ばれていないため廃止予定
    # おそらく既に呼ばれないはずだが、削除を失念した。リリース前なので一旦そのままとする。
    def transaction_products_ticket(order, ticket)
      hold_daily_schedule = order.seat_sale.hold_daily_schedule
      name = {
        promoterYear: hold_daily_schedule.promoter_year,
        period: hold_daily_schedule.period,
        round: hold_daily_schedule.round,
        highPriorityEventName: hold_daily_schedule.high_priority_event_code
      }
      sku_number = case ticket.area_code
                   when 'U', 'V'
                     ticket.name
                   else
                     "#{ticket.row ? ticket.row + '列' : ''}#{ticket.seat_number}番"
                   end
      seat_type_option_id = ticket.current_ticket_reserve ? ticket.current_ticket_reserve.seat_type_option_id : TicketReserve.where(ticket_id: ticket).not_transfer_ticket_reserve.filter_ticket_reserves.last.seat_type_option_id
      price = if SeatTypeOption.exists?(id: seat_type_option_id)
                ticket.price + SeatTypeOption.find(seat_type_option_id).price
              elsif order.coupon.present?
                ticket.price - (ticket.price * order.coupon.rate / 100.to_f).round
              else
                ticket.price
              end

      {
        name: name,
        sku: "#{ticket.coordinate_seat_type_name} #{sku_number}",
        price: price,
        quantity: 1
      }
    end

    # ☆廃止予定からしか呼ばれていないため廃止予定
    # おそらく既に呼ばれないはずだが、削除を失念した。リリース前なので一旦そのままとする。
    def transaction_id(order_id)
      # 本番環境の場合はそのまま返す
      return order_id if Rails.env.production?

      # それ以外の場合は環境名をつける
      "#{Rails.env}#{order_id}"
    end
  end
end

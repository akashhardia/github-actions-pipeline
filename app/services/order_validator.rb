# frozen_string_literal: true

# チェック項目
# 1. 存在しないチケットidが含まれていないか
# 2. 販売マスターの販売ステータスが販売中(on_sale)かどうか
# 3. チケットが販売期間内かどうか
# 4. チケットが購入可能ステータス(available)かどうか
# 5. 異なるエリアのチケットが混じっていないかどうか
# 6. 異なる販売マスターのチケットが混じっていないかどうか
# 7-A-1. 座席単体購入上限の4席を超えていないかどうか
# 7-A-2. 単体販売のチケットとBox席のチケットが混じっていないかどうか
# 7-B-1. Box席のチケットの場合は、セットで販売されているチケットが全てカートに含まれているかどうか
# 7-B-2. Box席のチケットと単体販売のチケットが混じっていないかどうか
# 8. 選択したオプション価格がチケットに対応するものかどうか
# 9. 選択されたクーポンは適用可能かどうか
# 10. 選択されたキャンペーンは適用可能かどうか
class OrderValidator
  # 単体座席の購入上限数
  PURCHASE_LIMIT_FOR_SINGLE = 8

  attr_reader :orders, :ticket_ids, :tickets, :seat_sale, :area_code, :user, :coupon_id, :decision, :campaign_code

  def initialize(orders, coupon_id, campaign_code, user, decision = nil)
    @orders = orders
    @ticket_ids = orders.map { |o| o[:ticket_id] }
    @tickets = Ticket.includes(:seat_area, seat_type: :seat_sale).where(id: ticket_ids)
    @area_code = tickets.first&.area_code
    @seat_sale = tickets.first&.seat_type&.seat_sale
    @user = user
    @coupon_id = coupon_id
    @decision = decision
    @campaign_code = campaign_code
  end

  def validation_error
    check_for_common_consistency(seat_sale, tickets, ticket_ids) ||
      check_concurrent_purchase_limit(seat_sale, tickets) ||
      check_for_sales_type(tickets, ticket_ids) ||
      check_for_option_ticket(tickets, orders) ||
      check_for_coupon_and_option(orders, coupon_id) ||
      check_for_campaign_and_option(orders, campaign_code) ||
      check_for_coupon_and_campaign(coupon_id, campaign_code) ||
      check_for_coupon(coupon_id, user, decision) ||
      check_for_campaign(campaign_code, user)
  end

  private

  def check_for_common_consistency(seat_sale, tickets, ticket_ids)
    # 共通の整合性チェック
    return :cart_is_empty if ticket_ids.blank?
    return :ticket_not_found if tickets.size != ticket_ids.size

    return :unapproved_sales unless seat_sale.on_sale?
    return :sale_term_outside unless seat_sale.check_sales_schedule?

    return :unapproved_sales unless tickets.first.seat_area.displayable?
    return :ticket_not_available unless tickets.all?(&:available?)
    return :ticket_not_available unless tickets.all? { |ticket| ticket.user_id.nil? }
  end

  def check_concurrent_purchase_limit(seat_sale, tickets)
    # 同時購入制限チェック
    return :seat_area_mismatch unless tickets.all? { |ticket| area_code == ticket.area_code }
    return :seat_sale_mismatch unless tickets.all? { |ticket| ticket.seat_type.seat_sale_id == seat_sale.id }
  end

  def check_for_sales_type(tickets, ticket_ids)
    # 販売タイプ別チェック
    if tickets.first.single?
      return :exceed_purchase_limit if tickets.size > PURCHASE_LIMIT_FOR_SINGLE
      return :sales_type_mismatch unless tickets.all?(&:single?)
    else
      master_seat_unit = tickets.first.master_seat_unit
      return :excess_or_deficiency_unit_ticket unless master_seat_unit.tickets.joins(:seat_type).where('seat_types.seat_sale_id = ?', seat_sale.id).distinct.ids.sort == ticket_ids.sort
      return :sales_type_mismatch unless tickets.all?(&:unit?)
    end
  end

  def check_for_option_ticket(tickets, orders)
    # オプション整合性チェック
    tickets.each do |ticket|
      order = orders.find { |o| o[:ticket_id].to_i == ticket.id }
      next if order[:option_id].nil?

      return :seat_type_option_mismatch unless ticket.seat_type.seat_type_option_ids.include?(order[:option_id].to_i)
    end
    nil
  end

  def check_for_coupon_and_option(orders, coupon_id)
    return if coupon_id.blank?
    # coupon_idがあり、全てのオーダーにオプションがある場合はエラー
    return :option_and_coupon_cannot_be_used_at_same_time if orders.all? { |order| order[:option_id] }
  end

  def check_for_campaign_and_option(orders, campaign_code)
    return if campaign_code.blank?
    # campaign_codeがあり、全てのオーダーにオプションがある場合はエラー
    return :option_and_campaign_cannot_be_used_at_same_time if orders.all? { |order| order[:option_id] }
  end

  def check_for_coupon(coupon_id, user, decision)
    return if coupon_id.nil?

    coupon = user.coupons.find_by(id: coupon_id)
    # userが持っているクーポンか、持っていても未使用かどうか
    return :coupon_not_found if coupon.blank?

    return :coupon_not_found if decision != 'request_completed' && !coupon.be_unused_user_coupon(user, coupon)

    # 利用終了日時を過ぎていないか
    return :coupon_available_deadline_has_passed if coupon.available_end_at < Time.zone.now

    # 全開催デイリー(hold_daily_schedule)が対象の場合はnilを返す
    return if coupon.coupon_hold_daily_conditions.blank?

    # check_concurrent_purchase_limitでticketsが同じseat_saleであることは保証済み
    hold_daily_schedule_id = tickets.first.display_hold_daily_schedule_id

    # coupon_idがcoupon_hold_daily_conditionsテーブルにある場合(全開催をクーポン適用としていない場合)、対象の開催で使用できるクーポンか
    return :coupon_hold_daily_schedules_mismatch unless coupon.coupon_hold_daily_conditions.pluck(:hold_daily_schedule_id).include?(hold_daily_schedule_id)
  end

  def check_for_coupon_and_campaign(coupon_id, campaign_code)
    return :coupon_and_campaign_cannot_use_at_same_time if coupon_id.present? && campaign_code.present?
  end

  def check_for_campaign(campaign_code, user)
    return if campaign_code.nil?

    campaign = Campaign.where.not(approved_at: nil).find_by(code: campaign_code)

    return :campaign_not_found if campaign.blank?

    hold_daily_schedule_id = tickets.first.hold_daily_schedule.id

    return :campaign_hold_daily_schedules_mismatch if campaign.hold_daily_schedules.present? && campaign.hold_daily_schedules.pluck(:id).exclude?(hold_daily_schedule_id)

    master_seat_type = tickets.first.master_seat_type

    return :campaign_master_seat_types_mismatch if campaign.master_seat_types.present? && campaign.master_seat_types.exclude?(master_seat_type)

    return :campaign_has_terminated if campaign.terminated_at.present?

    other_check_for_campaign(campaign, user)
  end

  def other_check_for_campaign(campaign, user)
    return :campaign_before_start if campaign.start_at.present? && Time.zone.now < campaign.start_at

    return :campaign_after_end if campaign.end_at.present? && Time.zone.now > campaign.end_at

    return :campaign_already_used if campaign.orders.captured.map(&:user).include?(user)

    return :campaign_usage_count_over_limit if campaign.orders.captured.map(&:user).uniq.count >= campaign.usage_limit
  end
end

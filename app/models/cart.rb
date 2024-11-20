# frozen_string_literal: true

# 座席選択state管理、座席一時キープなど
class Cart
  include Redis::Objects

  CART_EXPIRATION = 15.minutes.freeze

  attr_reader :user

  value :ticket_orders, marshal: true, expiration: CART_EXPIRATION

  def initialize(user)
    @user = user
  end

  def id
    "Cart-user_id=#{user.id}"
  end

  def purchase_order
    PurchaseOrder.new(self)
  end

  def orders
    @orders ||= ticket_orders.value
  end

  def cart_ticket_ids
    orders.present? ? orders[:orders]&.map { |order| order[:ticket_id] } : []
  end

  def tickets
    @tickets ||= Ticket.where(id: cart_ticket_ids)
  end

  def seat_sale
    @seat_sale ||= tickets.first.seat_type.seat_sale
  end

  def hold_daily_schedule
    @hold_daily_schedule ||= seat_sale.hold_daily_schedule
  end

  def charge_id
    return nil if ticket_orders.value.nil?

    ticket_orders[:charge_id]
  end

  def init_cart_resource(orders, tickets, coupon_id, campaign_code)
    @orders = { coupon_id: coupon_id, campaign_code: campaign_code, orders: orders, charge_id: nil }
    @tickets = tickets
    @seat_sale = tickets.first.seat_type.seat_sale
    @hold_daily_schedule = @seat_sale.hold_daily_schedule
  end

  # orders
  # [
  #  { ticket_id: 1, option_id: nil },
  #  { ticket_id: 2, option_id: 1 }
  # ]
  def replace_tickets(orders, coupon_id, campaign_code)
    order_validator = OrderValidator.new(orders, coupon_id, campaign_code, user)
    error_code = order_validator.validation_error
    return error_code if error_code

    clear_hold_tickets
    ticket_ids = orders.map { |order| order[:ticket_id].to_i }
    tickets = Ticket.where(id: ticket_ids)
    succeed = try_hold_tickets(tickets)
    return :ticket_not_available unless succeed

    ticket_orders.value = { coupon_id: coupon_id, campaign_code: campaign_code, orders: orders, charge_id: nil }

    init_cart_resource(orders, tickets, coupon_id, campaign_code)
    nil
  end

  def recheck_ownership(extend_ttl = nil)
    tickets.all? { |ticket| ticket.temporary_owner?(user.id, extend_ttl) }
  end

  def clear_hold_tickets
    return if ticket_orders.value.nil?

    tickets.each do |ticket|
      ticket.ticket_release(user.id)
    end
    ticket_orders.clear
  end

  def replace_cart_charge_id(prm_charge_id)
    # charge_idを設定する　ticket_orders内容差し替え
    old_ticket_orders = ticket_orders
    ticket_orders.value = { coupon_id: old_ticket_orders[:coupon_id], campaign_code: old_ticket_orders[:campaign_code], orders: old_ticket_orders[:orders], charge_id: prm_charge_id }
  end

  private

  def try_hold_tickets(tickets)
    accepted_ticket_ids = []
    succeed = true
    tickets.each do |ticket|
      result = ticket.try_reserve(user.id)
      if result
        accepted_ticket_ids << ticket.id
      else
        # 指定された座席のうちどれか一つでも確保できなかった場合は失敗扱いにする
        succeed = false
        break
      end
    end

    # 確保したチケットの解放
    unless succeed
      accepted_ticket_ids.each do |ticket_id|
        ticket = tickets.find { |t| t.id == ticket_id }
        ticket.ticket_release(user.id)
      end
    end

    succeed
  end
end

# frozen_string_literal: true

# カート内容のリスト表示・合計金額の計算など
class PurchaseOrder
  attr_reader :cart

  def initialize(cart)
    @cart = cart
  end

  def total_price
    return subtotal_price - coupon_discount_amount if coupon_discount_amount.positive?
    return subtotal_price - campaign_total_discount_amount if campaign_total_discount_amount.positive?

    subtotal_price
  end

  def subtotal_price # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
    return 0 if cart.tickets.blank?

    option_ids = cart.orders[:orders].map { |order| order[:option_id] }.compact
    if cart.tickets.first.single?
      return cart.tickets.sum(&:price) if option_ids.empty?

      cart.tickets.sum do |ticket|
        option = ticket.seat_type.seat_type_options.includes(:template_seat_type_option).find { |op| op.id == find_orders_by_ticket_id(ticket.id)[:option_id].to_i }
        ticket.price + option&.price.to_i
      end
    else
      return cart.tickets.first.price if option_ids.empty?

      options_price = cart.tickets.sum do |ticket|
        option = ticket.seat_type.seat_type_options.includes(:template_seat_type_option).find { |op| op.id == find_orders_by_ticket_id(ticket.id)[:option_id].to_i }
        option&.price.to_i
      end

      cart.tickets.first.price + options_price
    end
  end

  # front用
  def to_response_hash
    raise SeatSalesFlowError, I18n.t('custom_errors.orders.cart_is_empty') if cart.ticket_orders.value.blank?

    ticket = cart.tickets.first

    {
      # TODO: paymentは削除予定
      payment: 'ご登録済みクレジットカード',
      areaId: ticket.seat_area.id,
      areaName: ticket.area_name,
      areaCode: ticket.seat_area.area_code,
      position: ticket.seat_area.position,
      salesType: ticket.sales_type,
      unitName: ticket.master_seat_unit&.unit_name,
      unitType: ticket.master_seat_unit&.seat_type,
      holdDailySchedule: hold_daily_schedule_info,
      ticketList: ticket_list,
      totalPrice: subtotal_price,
      couponInfo: cart.orders[:coupon_id] && coupon_info,
      campaignInfo: cart.orders[:campaign_code] && campaign_info
    }
  end

  def coupon_discount_amount
    return 0 unless cart.orders[:coupon_id]

    coupon = Coupon.find(cart.orders[:coupon_id])

    cart.orders[:orders].each_with_index.inject(0) do |sum, (order, index)|
      next sum if cart.tickets.first.unit? && index.positive?

      ticket = cart.tickets.find { |t| t.id == order[:ticket_id].to_i }
      # オプションが無い、且つcoupon_seat_type_conditionsがある場合はseat_typeで適用できるクーポンかどうか
      next sum if order[:option_id].present?

      conditions = coupon.coupon_seat_type_conditions

      next sum unless conditions.blank? || conditions.exists?(master_seat_type_id: ticket.seat_type.master_seat_type_id)

      # 小数点以下が発生した場合は切り捨て
      sum + (ticket.price * coupon.rate / 100).floor
    end
  end

  def campaign_total_discount_amount
    return 0 unless cart.orders[:campaign_code]

    campaign = Campaign.find_by(code: cart.orders[:campaign_code])

    cart.orders[:orders].each_with_index.inject(0) do |sum, (order, index)|
      next sum if cart.tickets.first.unit? && index.positive?

      ticket = cart.tickets.find { |t| t.id == order[:ticket_id].to_i }

      # オプションとは併用不可
      next sum if order[:option_id].present?

      sum + (ticket.price * campaign.discount_rate / 100).floor
    end
  end

  def option_discount_amount
    return 0 if cart.tickets.first.unit?

    cart.tickets.inject(0) do |discount_amount, ticket|
      option = ticket.seat_type.seat_type_options.find_by(id: find_orders_by_ticket_id(ticket.id)[:option_id])
      discount_amount += option.price if option.present?
      discount_amount
    end
  end

  def product_list
    products = cart.orders[:orders].each_with_object({}).with_index do |(order, products_hash), index|
      next products_hash if cart.tickets.first.unit? && index.positive?

      ticket = cart.tickets.find { |t| t.id == order[:ticket_id].to_i }
      unit_price = ticket.price - discount_amount(ticket, order)
      products_hash[unit_price] = products_hash[unit_price] ? increment_product(products_hash[unit_price]) : init_product(unit_price)
    end

    products.values
  end

  private

  def find_orders_by_ticket_id(id)
    cart.orders[:orders].find { |order| order[:ticket_id].to_i == id }
  end

  def ticket_list
    return [] if cart.orders.nil? || cart.tickets.blank?

    cart.tickets.includes(seat_type: [:template_seat_type, seat_type_options: :template_seat_type_option]).map do |ticket|
      option = ticket.seat_type.seat_type_options.includes(:template_seat_type_option).find { |op| op.id == find_orders_by_ticket_id(ticket.id)[:option_id].to_i }
      price = cart.tickets.first.single? ? ticket.price + option&.price.to_i : 0
      {
        ticketId: ticket.id,
        row: ticket.row,
        seatNumber: ticket.seat_number,
        price: price,
        seatTypeOptionList: seat_type_option_list(ticket.seat_type.seat_type_options),
        optionId: option&.id,
        optionTitle: option&.title
      }
    end
  end

  def seat_type_option_list(seat_type_options)
    seat_type_options.map do |seat_type_option|
      {
        id: seat_type_option.id,
        optionTitle: seat_type_option.title,
        optionDescription: seat_type_option.description,
        optionPrice: seat_type_option.price
      }
    end
  end

  def coupon_info
    coupon = cart.user.coupons.available(Time.zone.now).find(cart.orders[:coupon_id])
    {
      couponTitle: coupon.title,
      couponRate: coupon.rate,
      discountAmount: coupon_discount_amount
    }
  end

  def campaign_info
    campaign = Campaign.find_by(code: cart.orders[:campaign_code])
    {
      campaignTitle: campaign.title,
      campaignDiscountRate: campaign.discount_rate,
      totalDiscountAmount: campaign_total_discount_amount
    }
  end

  def hold_daily_schedule_info
    {
      dailyNo: cart.hold_daily_schedule.daily_no,
      eventDate: cart.hold_daily_schedule.event_date,
      dayOfWeek: cart.hold_daily_schedule.event_date.wday,
      promoterYear: cart.hold_daily_schedule.promoter_year,
      period: cart.hold_daily_schedule.period,
      round: cart.hold_daily_schedule.round,
      highPriorityEventCode: cart.hold_daily_schedule.high_priority_event_code,
      openAt: cart.hold_daily_schedule.opening_display,
      startAt: cart.hold_daily_schedule.start_display
    }
  end

  def discount_amount(ticket, order) # rubocop:disable Metrics/PerceivedComplexity
    discount_amount = if order[:option_id].present?
                        ticket.seat_type.seat_type_options.find_by(id: order[:option_id])&.price
                      elsif cart.orders[:coupon_id].present?
                        coupon = Coupon.find_by(id: cart.orders[:coupon_id])
                        conditions = coupon&.coupon_seat_type_conditions

                        (ticket.price * coupon.rate / 100).floor if coupon && conditions.blank? || conditions.exists?(master_seat_type_id: ticket.seat_type.master_seat_type_id)
                      elsif cart.orders[:campaign_code].present?
                        campaign = Campaign.find_by(code: cart.orders[:campaign_code])

                        (ticket.price * campaign.discount_rate / 100).floor if campaign
                      end
    discount_amount.to_i.abs
  end

  def init_product(unit_price)
    {
      amount: unit_price,
      name: 'PIST6 入場チケット',
      quantity: 1,
      unit_price: unit_price,
      delivery_schedule: 'immediate',
      return_policy: 'no_return',
      note_url: "#{mt_host_name}/guide/ticket-guide/howto-buy/",
      note_type: 'limited_time_offers'
    }
  end

  def increment_product(product)
    unit_price = product[:unit_price]
    quantity = product[:quantity] + 1
    amount = unit_price * quantity

    {
      amount: amount,
      name: 'PIST6 入場チケット',
      quantity: quantity,
      unit_price: unit_price,
      delivery_schedule: 'immediate',
      return_policy: 'no_return',
      note_url: "#{mt_host_name}/guide/ticket-guide/howto-buy/",
      note_type: 'limited_time_offers'
    }
  end

  def mt_host_name
    @mt_host_name ||= Rails.application.credentials.environmental[:mt_host_name]
  end
end

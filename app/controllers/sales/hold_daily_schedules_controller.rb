# frozen_string_literal: true

module Sales
  # チケット販売画面開催デイリーコントローラ
  class HoldDailySchedulesController < ApplicationController
    def index
      on_sale_holds = Hold.joins(hold_dailies: [hold_daily_schedules: :seat_sales])
                          .where(seat_sales: { sales_status: 'on_sale' })
                          .where('seat_sales.sales_start_at <= ? and seat_sales.sales_end_at > ?', Time.zone.now, Time.zone.now)
                          .order('hold_dailies.event_date')
                          .uniq

      holds_result = []

      on_sale_holds.each do |hold|
        hold_dailies_result = []
        hold_dailies = hold.hold_dailies.joins(hold_daily_schedules: [:seat_sales])
                           .where(seat_sales: { sales_status: 'on_sale' })
                           .where('seat_sales.sales_start_at <= ? and seat_sales.sales_end_at > ?', Time.zone.now, Time.zone.now)
                           .order(:event_date)
                           .distinct

        hold_dailies.each do |hold_daily|
          hold_daily_schedules = hold_daily.hold_daily_schedules.includes(:races, :seat_sales)
                                           .where(seat_sales: { sales_status: 'on_sale' })
                                           .where('seat_sales.sales_start_at <= ? and seat_sales.sales_end_at > ?', Time.zone.now, Time.zone.now)
                                           .order(:daily_no)

          serialized_hold_daily_schedules = ActiveModelSerializers::SerializableResource.new(hold_daily_schedules,
                                                                                             each_serializer: ::Sales::HoldDailyScheduleSerializer,
                                                                                             key_transform: :camel_lower)
          hold_dailies_result << { id: hold_daily.id,
                                   eventDate: hold_daily.event_date,
                                   holdDailySchedules: serialized_hold_daily_schedules }
        end
        holds_result << { id: hold.id,
                          promoterYear: hold.promoter_year,
                          period: hold.period,
                          round: hold.round,
                          holdDailies: hold_dailies_result }
      end

      render json: holds_result
    end

    def area_sales_info
      hold_daily_schedule = HoldDailySchedule.find(params[:id])
      seat_sale = hold_daily_schedule.seat_sales.find(&:on_sale?)
      seat_areas = seat_sale.seat_areas.includes(:master_seat_area, tickets: { seat_type: [:template_seat_type, :master_seat_type] })

      result = {}.tap do |hash|
        hash['areas'] = []
        hash['holdDailySchedule'] = ActiveModelSerializers::SerializableResource.new(hold_daily_schedule, key_transform: :camel_lower)
        seat_areas.each do |seat_area|
          area_tickets = seat_area.tickets
          min_price = area_tickets.each_with_object([]) do |ticket, arr|
            arr << ticket.price if ticket.available?
          end.min
          seat_types = area_tickets.select(&:available?).uniq(&:seat_type_id).map { |ticket| { seatTypeName: ticket.name, price: ticket.price } }
          hash['areas'] << { id: seat_area.id, areaName: seat_area.area_name, minPrice: min_price, positionTxt: seat_area.position, availableSale: area_tickets.any?(&:available?), display: seat_area.displayable, areaCode: seat_area.area_code, seatTypePriceList: seat_types }
        end
      end

      render json: result
    end
  end
end

# frozen_string_literal: true

module Admin
  # チケット販売状況などのカウントを返すエリア一覧用
  class IndexSeatAreaSerializer < SeatAreaSerializer
    attributes :area_sales_type, :available_seats_count, :sold_seats_count, :not_for_sale_seats_count,
               :available_unit_seats_count, :sold_unit_seats_count, :not_for_sale_unit_seats_count

    def area_sales_type
      tickets.first.sales_type
    end

    def available_seats_count
      tickets.count(&:available?)
    end

    def sold_seats_count
      tickets.count(&:sold?)
    end

    def not_for_sale_seats_count
      tickets.count(&:not_for_sale?)
    end

    def available_unit_seats_count
      tickets.filter(&:master_seat_unit_id).uniq(&:master_seat_unit_id).count(&:available?)
    end

    def sold_unit_seats_count
      tickets.filter(&:master_seat_unit_id).uniq(&:master_seat_unit_id).count(&:sold?)
    end

    def not_for_sale_unit_seats_count
      tickets.filter(&:master_seat_unit_id).uniq(&:master_seat_unit_id).count(&:not_for_sale?)
    end

    private

    def tickets
      object.tickets
    end
  end
end

# frozen_string_literal: true

module Admin
  # 座席テンプレートの各ステータスのカウントを返すテンプレートエリア一覧用
  class IndexTemplateSeatAreaSerializer < TemplateSeatAreaSerializer
    attributes :area_name, :area_code, :position, :area_sales_type, :available_seats_count, :not_for_sale_seats_count,
               :available_unit_seats_count, :not_for_sale_unit_seats_count

    def area_sales_type
      template_seats.first.sales_type
    end

    def available_seats_count
      template_seats.count(&:available?)
    end

    def not_for_sale_seats_count
      template_seats.count(&:not_for_sale?)
    end

    def available_unit_seats_count
      template_seats.filter(&:master_seat_unit_id).uniq(&:master_seat_unit_id).count(&:available?)
    end

    def not_for_sale_unit_seats_count
      template_seats.filter(&:master_seat_unit_id).uniq(&:master_seat_unit_id).count(&:not_for_sale?)
    end

    private

    def template_seats
      object.template_seats
    end
  end
end

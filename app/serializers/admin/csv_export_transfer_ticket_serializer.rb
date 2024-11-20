# frozen_string_literal: true

module Admin
  # 管理画面CSVエクスポート用譲渡チケットシリアライザー
  class CsvExportTransferTicketSerializer < ActiveModel::Serializer
    attributes :id, :row, :seat_number, :event_date, :area_name, :unit_name, :count, :transfer_uuid, :daily_no, :season, :period

    def event_date
      object.seat_sale.hold_daily_schedule.hold_daily.event_date
    end

    def daily_no
      object.seat_sale.hold_daily_schedule.daily_no
    end

    def area_name
      object.seat_area.master_seat_area.area_name
    end

    def unit_name
      return nil if object.single?

      if master_seat_unit&.seat_type == 'box'
        object.position
      else
        master_seat_unit&.unit_name
      end
    end

    def count
      return 1 if master_seat_unit.blank?

      master_seat_unit.master_seats.count
    end

    delegate :season, to: :hold

    delegate :period, to: :hold

    def seat_number
      if object.single?
        "#{object.sub_code || ''}#{object.seat_number}"
      elsif object.unit? && object.master_seat_unit&.seat_type == 'box'
        "#{object.sub_code || ''}#{object.master_seat_unit&.unit_name}"
      else
        '-'
      end
    end

    private

    def master_seat_unit
      object.master_seat_unit
    end

    def hold
      object.seat_sale.hold
    end
  end
end

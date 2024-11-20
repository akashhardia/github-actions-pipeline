# frozen_string_literal: true

module Admin
  # 管理画面CSVエクスポート用注文シリアライザー
  class CsvExportOrderSerializer < ActiveModel::Serializer
    attributes :id, :user_id, :created_at, :returned_at, :total_price, :coupon_discount, :option_discount,
               :event_date, :daily_no, :seat_sale_id, :coupon_id, :charge_id, :campaign_id, :campaign_title,
               :campaign_discount

    delegate :charge_id, to: :payment

    def returned_at
      object.returned_at&.strftime('%Y-%m-%d %H:%M:%S')
    end

    def event_date
      object.seat_sale.hold_daily_schedule.hold_daily.event_date
    end

    def daily_no
      object.seat_sale.hold_daily_schedule.daily_no
    end

    def coupon_id
      object.user_coupon&.coupon_id
    end

    def created_at
      object.created_at&.strftime('%Y-%m-%d %H:%M:%S')
    end

    def campaign_id
      object.campaign&.id
    end

    def campaign_title
      object.campaign&.title&.gsub(',', '_')
    end

    private

    def payment
      object.payment
    end
  end
end

# frozen_string_literal: true

module Admin
  # 管理画面の購入履歴
  class OrderSerializer < ActiveModel::Serializer
    attributes :id, :total_price, :created_at, :payment_status, :returned_at

    delegate :daily_no, :hold_name_jp, :event_date, to: :hold_daily_schedule

    # 購入履歴一覧ページでのみ使用する値
    attribute :daily_no, if: :index?
    attribute :hold_name_jp, if: :index?
    attribute :event_date, if: :index?
    attribute :ticket_count, if: :index?

    # 購入詳細ページでのみ使用する値
    attribute :used_coupon, if: :show?

    def initialize(serializer, options = {})
      @instance_options = options
      super
    end

    def index?
      @instance_options[:action] == :index
    end

    def show?
      @instance_options[:action] == :show
    end

    def payment_status
      object.payment&.payment_progress
    end

    def ticket_count
      object.ticket_reserves.length
    end

    def used_coupon
      object.coupon.present? ? "#{object.coupon.title}(ID: #{object.coupon.id})" : '無し'
    end

    private

    def hold_daily_schedule
      object.seat_sale.hold_daily_schedule
    end
  end
end

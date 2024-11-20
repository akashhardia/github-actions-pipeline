# frozen_string_literal: true

module Admin
  # 管理画面用キャンペーンシリアライザー
  class CampaignSerializer < ActiveModel::Serializer
    attributes :id, :title, :code, :discount_rate, :usage_limit, :description,
               :start_at, :end_at, :approved_at, :terminated_at, :displayable,
               :hold_daily_schedules, :master_seat_types

    # キャンペーン一覧ページでのみ使用する値
    attribute :created_at, if: :index?
    attribute :updated_at, if: :index?

    # キャンペーン詳細ページでのみ使用する値
    attribute :current_usages_count, if: :show?

    def index?
      @instance_options[:action] == :index
    end

    def show?
      @instance_options[:action] == :show
    end

    def current_usages_count
      object.orders.joins(:payment).where(payment: { payment_progress: :captured }).pluck(:user_id).uniq.count
    end

    def hold_daily_schedules
      wd = %w[日 月 火 水 木 金 土].freeze

      object.hold_daily_schedules.includes(hold_daily: :hold).map do |hold_daily_schedule|
        daily_no_display = HoldDailySchedule::DAILY_NO[hold_daily_schedule.daily_no.to_sym]

        event_date_display = hold_daily_schedule.event_date.strftime("%Y/%m/%d(#{wd[hold_daily_schedule.event_date.wday]})")
        hold_name_display = "#{daily_no_display} #{event_date_display} #{hold_daily_schedule.hold_name_jp}"
        {
          id: hold_daily_schedule.id,
          name: hold_name_display
        }
      end
    end

    def master_seat_types
      object.master_seat_types.map do |master_seat_type|
        {
          id: master_seat_type.id,
          name: master_seat_type.name
        }
      end
    end
  end
end

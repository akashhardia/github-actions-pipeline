# frozen_string_literal: true

module Admin
  # キャンペーンコントローラー
  class CampaignsController < ApplicationController
    before_action :snakeize_params
    before_action :set_campaign, only: [:show, :update, :destroy, :approve, :terminate]

    def index
      campaigns = Campaign.includes(:master_seat_types)
      campaigns_by_type = case params[:type]
                          when 'not_approved'
                            # 未承認キャンペーン
                            campaigns.where(approved_at: nil)
                          when 'approved'
                            # 承認済みキャンペーン
                            campaigns.where.not(approved_at: nil)
                          else
                            # すべてのキャンペーン
                            campaigns
                          end
      paginated_campaigns = campaigns_by_type.order(id: :desc).page(params[:page] || 1).per(10)
      pagination = resources_with_pagination(paginated_campaigns)
      serialized_campaigns = ActiveModelSerializers::SerializableResource.new(paginated_campaigns,
                                                                              each_serializer: Admin::CampaignSerializer,
                                                                              action: :index,
                                                                              key_transform: :camel_lower)
      render json: { campaigns: serialized_campaigns, pagination: pagination }
    end

    def show
      render json: @campaign, serializer: Admin::CampaignSerializer, action: :show, key_transform: :camel_lower
    end

    # キャンペーン割引新規登録画面に必要な初期データを取得
    def new
      hold_daily_schedules = HoldDailySchedule.includes(:seat_sales).select do |hold_daily_schedule|
        hold_daily_schedule&.available?
      end
      # hold_daily_schedulesが取得できれば、先読みして渡す。取得できなければ空配列を返す
      hold_daily_schedules = hold_daily_schedules.present? ? HoldDailySchedule.includes(hold_daily: :hold).where(id: hold_daily_schedules) : []

      serialized_hold_daily_schedules = ActiveModelSerializers::SerializableResource.new(hold_daily_schedules, each_serializer: HoldDailyScheduleForCouponSerializer, key_transform: :camel_lower)
      serialized_master_seat_types = ActiveModelSerializers::SerializableResource.new(MasterSeatType.all, each_serializer: MasterSeatTypeSerializer, key_transform: :camel_lower)

      render json: { holdDailySchedules: serialized_hold_daily_schedules, masterSeatTypes: serialized_master_seat_types }, status: :ok
    end

    def create
      new_campaign = CampaignCreator.new(params).create_campaign!

      render json: new_campaign, serializer: Admin::CampaignSerializer, key_transform: :camel_lower, status: :ok
    end

    def update
      if @campaign.approved_at.present? && (
        @campaign.code != update_campaign_params[:code] ||
        @campaign.discount_rate != update_campaign_params[:discount_rate].to_i ||
        @campaign.usage_limit != update_campaign_params[:usage_limit].to_i ||
        @campaign.start_at != update_campaign_params[:start_at] ||
        @campaign.end_at != update_campaign_params[:end_at])

        raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.campaigns.uneditable_after_approved')
      end

      ActiveRecord::Base.transaction do
        @campaign.update!(update_campaign_params)
      end

      head :ok
    end

    def destroy
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.campaigns.already_used') if @campaign.campaign_usages.present?
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.campaigns.not_destroy') if @campaign.approved_at

      @campaign.destroy!
      head :ok
    end

    def approve
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.campaigns.already_approved') if @campaign.approved_at.present?

      @campaign.update!(approved_at: Time.zone.now)
      head :ok
    end

    def terminate
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.campaigns.please_approve') if @campaign.approved_at.blank?
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.campaigns.already_terminated') if @campaign.terminated_at.present?

      @campaign.update!(terminated_at: Time.zone.now)
      head :ok
    end

    private

    def set_campaign
      @campaign = Campaign.find(params[:id])
    end

    def update_campaign_params
      {
        title: params[:campaign][:title],
        code: params[:campaign][:code],
        discount_rate: params[:campaign][:discount_rate],
        usage_limit: params[:campaign][:usage_limit],
        description: params[:campaign][:description],
        start_at: params[:campaign][:start_at].present? ? "#{params[:campaign][:start_at]} 00:00:00" : nil,
        end_at: params[:campaign][:end_at].present? ? "#{params[:campaign][:end_at]} 23:59:59" : nil,
        displayable: params[:campaign][:displayable],
        updated_at: Time.zone.now,
        hold_daily_schedule_ids: params[:hold_daily_schedule_ids],
        master_seat_type_ids: params[:master_seat_type_ids]
      }
    end
  end
end

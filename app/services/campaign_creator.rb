# frozen_string_literal: true

# キャンペーン関連モデルクリエーター
class CampaignCreator
  attr_reader :campaign_params, :hold_daily_schedule_ids, :master_seat_type_ids

  def initialize(params)
    parsed_campaign_params = JSON.parse(params[:campaign])
    @campaign_params = {
      title: parsed_campaign_params['title'],
      code: parsed_campaign_params['code'],
      discount_rate: parsed_campaign_params['discountRate'],
      usage_limit: parsed_campaign_params['usageLimit'],
      description: parsed_campaign_params['description'],
      start_at: parsed_campaign_params['startAt'].present? ? "#{parsed_campaign_params['startAt']} 00:00:00" : nil,
      end_at: parsed_campaign_params['endAt'].present? ? "#{parsed_campaign_params['endAt']} 23:59:59" : nil,
      displayable: params['displayable']
    }
    @hold_daily_schedule_ids = JSON.parse(params[:hold_daily_schedule_ids])
    @master_seat_type_ids = JSON.parse(params[:master_seat_type_ids])
  end

  def create_campaign!
    ActiveRecord::Base.transaction do
      campaign = Campaign.create!(campaign_params)
      create_campaign_hold_daily_schedules(hold_daily_schedule_ids, campaign)
      create_campaign_master_seat_types(master_seat_type_ids, campaign)
      campaign
    end
  end

  private

  def create_campaign_hold_daily_schedules(hold_daily_schedule_ids, campaign)
    hold_daily_schedules = HoldDailySchedule.where(id: hold_daily_schedule_ids)
    raise CustomError.new(http_status: :not_found, code: 'not_found_hold_daily'), I18n.t('custom_errors.campaigns.not_found_hold_daily') unless hold_daily_schedules.size == hold_daily_schedule_ids.size

    campaign_hold_daily_schedules = hold_daily_schedules.map do |hold_daily_schedule|
      CampaignHoldDailySchedule.new(campaign: campaign, hold_daily_schedule: hold_daily_schedule)
    end

    CampaignHoldDailySchedule.import! campaign_hold_daily_schedules
  end

  def create_campaign_master_seat_types(master_seat_type_ids, campaign)
    master_seat_types = MasterSeatType.where(id: master_seat_type_ids)
    raise CustomError.new(http_status: :not_found, code: 'not_found_seat_type'), I18n.t('custom_errors.campaigns.not_found_seat_type') unless master_seat_types.size == master_seat_type_ids.size

    campaign_master_seat_types = master_seat_types.map do |master_seat_type|
      CampaignMasterSeatType.new(campaign: campaign, master_seat_type: master_seat_type)
    end

    CampaignMasterSeatType.import! campaign_master_seat_types
  end
end

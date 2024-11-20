# frozen_string_literal: true

# == Schema Information
#
# Table name: campaign_hold_daily_schedules
#
#  id                     :bigint           not null, primary key
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  campaign_id            :bigint           not null
#  hold_daily_schedule_id :bigint           not null
#
# Indexes
#
#  index_campaign_hold_daily_schedules_on_campaign_id             (campaign_id)
#  index_campaign_hold_daily_schedules_on_hold_daily_schedule_id  (hold_daily_schedule_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (hold_daily_schedule_id => hold_daily_schedules.id)
#
require 'rails_helper'

RSpec.describe CampaignHoldDailySchedule, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

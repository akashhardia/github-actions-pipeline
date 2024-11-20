# frozen_string_literal: true

# == Schema Information
#
# Table name: campaign_master_seat_types
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  campaign_id         :bigint           not null
#  master_seat_type_id :bigint           not null
#
# Indexes
#
#  index_campaign_master_seat_types_on_campaign_id          (campaign_id)
#  index_campaign_master_seat_types_on_master_seat_type_id  (master_seat_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (master_seat_type_id => master_seat_types.id)
#
class CampaignMasterSeatType < ApplicationRecord
  belongs_to :campaign
  belongs_to :master_seat_type
end
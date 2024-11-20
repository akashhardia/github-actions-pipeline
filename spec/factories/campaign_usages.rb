# frozen_string_literal: true

# == Schema Information
#
# Table name: campaign_usages
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  campaign_id :bigint           not null
#  order_id    :bigint           not null
#
# Indexes
#
#  index_campaign_usages_on_campaign_id  (campaign_id)
#  index_campaign_usages_on_order_id     (order_id)
#
# Foreign Keys
#
#  fk_rails_...  (campaign_id => campaigns.id)
#  fk_rails_...  (order_id => orders.id)
#
FactoryBot.define do
  factory :campaign_usage do
    campaign
    order
  end
end

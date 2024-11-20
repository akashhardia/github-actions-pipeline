# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  approved_at   :datetime
#  code          :string(255)      not null
#  description   :string(255)
#  discount_rate :integer          not null
#  displayable   :boolean          default(TRUE)
#  end_at        :datetime
#  start_at      :datetime
#  terminated_at :datetime
#  title         :string(255)      not null
#  usage_limit   :integer          default(9999999), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_campaigns_on_code  (code) UNIQUE
#
class Campaign < ApplicationRecord
  has_many :campaign_hold_daily_schedules, dependent: :destroy
  has_many :hold_daily_schedules, through: :campaign_hold_daily_schedules
  has_many :campaign_master_seat_types, dependent: :destroy
  has_many :master_seat_types, through: :campaign_master_seat_types
  has_many :campaign_usages, dependent: :restrict_with_exception
  has_many :orders, through: :campaign_usages

  # Validations -----------------------------------------------------------------------------------
  validates :code, presence: true, uniqueness: { case_sensitive: true }, length: { maximum: 10 },
                   format: { with: /\A\w+\z/ }
  validates :discount_rate, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates_with CampaignDatetimeValidator
end

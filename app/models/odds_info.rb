# frozen_string_literal: true

# == Schema Information
#
# Table name: odds_infos
#
#  id             :bigint           not null, primary key
#  fixed          :boolean          not null
#  odds_time      :datetime         not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  entries_id     :string(255)      not null
#  race_detail_id :bigint           not null
#
# Indexes
#
#  index_odds_infos_on_race_detail_id  (race_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_detail_id => race_details.id)
#
class OddsInfo < ApplicationRecord
  belongs_to :race_detail
  has_many :odds_lists, dependent: :destroy

  # Validations -----------------------------------------------------------------------------------
  validates :fixed, inclusion: { in: [true, false] }
  validates :odds_time, presence: true
  validates :entries_id, presence: true
  validates :race_detail_id, presence: true

  scope :latest, -> {
    order(odds_time: :desc).first
  }
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: odds_lists
#
#  id           :bigint           not null, primary key
#  odds_count   :integer
#  vote_type    :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  odds_info_id :bigint           not null
#
# Indexes
#
#  index_odds_lists_on_odds_info_id  (odds_info_id)
#
# Foreign Keys
#
#  fk_rails_...  (odds_info_id => odds_infos.id)
#
class OddsList < ApplicationRecord
  belongs_to :odds_info
  has_many :odds_details, dependent: :destroy

  # Validations -----------------------------------------------------------------------------------
  validates :vote_type, presence: true
  validates :odds_info_id, presence: true

  enum vote_type: Rails.configuration.enum[:vote_type]
end

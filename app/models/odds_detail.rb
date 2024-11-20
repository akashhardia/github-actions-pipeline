# frozen_string_literal: true

# == Schema Information
#
# Table name: odds_details
#
#  id           :bigint           not null, primary key
#  odds_max_val :decimal(6, 1)
#  odds_val     :decimal(6, 1)    not null
#  tip1         :string(255)      not null
#  tip2         :string(255)
#  tip3         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  odds_list_id :bigint           not null
#
# Indexes
#
#  index_odds_details_on_odds_list_id  (odds_list_id)
#
# Foreign Keys
#
#  fk_rails_...  (odds_list_id => odds_lists.id)
#
class OddsDetail < ApplicationRecord
  belongs_to :odds_list

  # Validations -----------------------------------------------------------------------------------
  validates :tip1, presence: true
  validates :odds_val, presence: true
end

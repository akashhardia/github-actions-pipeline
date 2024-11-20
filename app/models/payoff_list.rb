# frozen_string_literal: true

# == Schema Information
#
# Table name: payoff_lists
#
#  id             :bigint           not null, primary key
#  payoff         :integer
#  payoff_type    :integer
#  tip1           :string(255)      not null
#  tip2           :string(255)
#  tip3           :string(255)
#  vote_type      :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  race_detail_id :bigint           not null
#
# Indexes
#
#  index_payoff_lists_on_race_detail_id  (race_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_detail_id => race_details.id)
#
class PayoffList < ApplicationRecord
  belongs_to :race_detail

  # Validations -----------------------------------------------------------------------------------
  validates :tip1, presence: true

  enum vote_type: Rails.configuration.enum[:vote_type]

  # MT用スコープ
  scope :mt_api_payoff_scope, ->(race_detail_id) do
    where(race_detail_id: race_detail_id)
      .where.not(payoff_type: nil)
      .where.not(vote_type: nil)
  end
end

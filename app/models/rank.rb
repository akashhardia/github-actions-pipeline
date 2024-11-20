# frozen_string_literal: true

# == Schema Information
#
# Table name: ranks
#
#  id             :bigint           not null, primary key
#  arrival_order  :integer          not null
#  car_number     :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  race_detail_id :bigint           not null
#
# Indexes
#
#  index_ranks_on_race_detail_id  (race_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_detail_id => race_details.id)
#
class Rank < ApplicationRecord
  belongs_to :race_detail

  # Validations -----------------------------------------------------------------------------------
  validates :arrival_order, presence: true
  validates :car_number, presence: true
end

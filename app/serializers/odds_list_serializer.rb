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
class OddsListSerializer < ApplicationSerializer
  has_many :odds_details
  attributes :id, :odds_info_id, :vote_type, :odds_count
end

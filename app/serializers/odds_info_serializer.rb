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
class OddsInfoSerializer < ApplicationSerializer
  has_many :odds_lists
  attributes :id, :race_detail_id, :fixed, :odds_time, :entries_id
end

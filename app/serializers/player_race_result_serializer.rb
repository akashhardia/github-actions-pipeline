# frozen_string_literal: true

# == Schema Information
#
# Table name: player_race_results
#
#  id           :bigint           not null, primary key
#  daily_status :integer
#  event_code   :string(255)
#  event_date   :date
#  hold_daily   :integer
#  race_no      :integer
#  race_status  :integer
#  rank         :integer
#  time         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  entries_id   :string(255)
#  hold_id      :string(255)
#  player_id    :bigint           not null
#
# Indexes
#
#  index_player_race_results_on_player_id  (player_id)
#
# Foreign Keys
#
#  fk_rails_...  (player_id => players.id)
#
class PlayerRaceResultSerializer < ActiveModel::Serializer
  attributes :event_date, :hold_daily, :race_no, :rank, :time, :created_at, :updated_at
end

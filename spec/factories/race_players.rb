# frozen_string_literal: true

# == Schema Information
#
# Table name: race_players
#
#  id             :bigint           not null, primary key
#  bike_no        :integer
#  bracket_no     :integer
#  gear           :decimal(3, 2)
#  miss           :boolean          not null
#  start_position :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  pf_player_id   :string(255)
#  race_detail_id :bigint           not null
#
# Indexes
#
#  index_race_players_on_race_detail_id  (race_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_detail_id => race_details.id)
#
FactoryBot.define do
  factory :race_player do
    race_detail
    miss { false }
    sequence(:pf_player_id)
    sequence(:bike_no)
  end

  trait :with_player do
    after(:create) do |race_player|
      player = create(:player, pf_player_id: race_player.pf_player_id, player_class: 1, regist_num: 1)
      create(:player_result, player_id: player.id, pf_player_id: player.pf_player_id)
      create(:player_original_info, player_id: player.id)
    end
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: bike_infos
#
#  id             :bigint           not null, primary key
#  frame_code     :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  race_player_id :bigint           not null
#
# Indexes
#
#  index_bike_infos_on_race_player_id  (race_player_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_player_id => race_players.id)
#
# バイク情報のSerializerモデル
class BikeInfoSerializer < ActiveModel::Serializer
  has_one :front_wheel_info
  has_one :rear_wheel_info
  attributes :id, :race_player_id, :brand_name_jp

  def brand_name_jp
    WordName.get_word_name('V02', object.frame_code, 'jp')&.name
  end
end

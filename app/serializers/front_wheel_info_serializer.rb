# frozen_string_literal: true

# == Schema Information
#
# Table name: front_wheel_infos
#
#  id           :bigint           not null, primary key
#  rental_code  :integer
#  wheel_code   :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  bike_info_id :bigint           not null
#
# Indexes
#
#  index_front_wheel_infos_on_bike_info_id  (bike_info_id)
#
# Foreign Keys
#
#  fk_rails_...  (bike_info_id => bike_infos.id)
#
# 前輪情報のSerializerモデル
class FrontWheelInfoSerializer < ActiveModel::Serializer
  attributes :id, :brand_name_jp, :rental_code

  def brand_name_jp
    WordName.get_word_name('V01', object.wheel_code, 'jp')&.name
  end
end

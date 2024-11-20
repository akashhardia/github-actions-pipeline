# frozen_string_literal: true

# == Schema Information
#
# Table name: master_seat_types
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# 席種マスターのSerializerモデル
class MasterSeatTypeSerializer < ActiveModel::Serializer
  attributes :id, :name
end

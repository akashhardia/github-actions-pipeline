# frozen_string_literal: true

# == Schema Information
#
# Table name: tracks
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  track_code :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :track do
    track_code { '00' }
    name { 'テスト 競技場名' }
  end
end

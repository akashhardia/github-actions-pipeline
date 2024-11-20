# frozen_string_literal: true

# == Schema Information
#
# Table name: race_results
#
#  id             :bigint           not null, primary key
#  bike_count     :integer
#  last_lap       :decimal(6, 4)
#  post_time      :string(255)
#  race_stts      :string(255)
#  race_time      :decimal(6, 4)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  entries_id     :string(255)      not null
#  race_detail_id :bigint           not null
#
# Indexes
#
#  index_race_results_on_race_detail_id  (race_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_detail_id => race_details.id)
#
require 'rails_helper'

RSpec.describe RaceResult, type: :model do
  describe 'バリデーション: 必須チェック' do
    it 'entries_idが必須チェックでエラーになること' do
      race_result = build(:race_result, entries_id: nil)
      expect(race_result.invalid?).to be true
      expect(race_result.errors.details[:entries_id][0][:error]).to eq(:blank)
    end
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: time_trial_results
#
#  id         :bigint           not null, primary key
#  confirm    :boolean
#  players    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  hold_id    :bigint           not null
#  pf_hold_id :string(255)      not null
#
# Indexes
#
#  index_time_trial_results_on_hold_id  (hold_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_id => holds.id)
#
require 'rails_helper'

RSpec.describe TimeTrialResult, type: :model do
  describe '#pf_hold_id' do
    it 'pf_hold_idが必須チェックでエラーになること' do
      time_trial_result = build(:time_trial_result, pf_hold_id: nil)
      expect(time_trial_result.invalid?).to be true
      expect(time_trial_result.errors.messages[:pf_hold_id]).to include('を入力してください')
    end
  end
end

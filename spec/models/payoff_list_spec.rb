# frozen_string_literal: true

# == Schema Information
#
# Table name: payoff_lists
#
#  id             :bigint           not null, primary key
#  payoff         :integer
#  payoff_type    :integer
#  tip1           :string(255)      not null
#  tip2           :string(255)
#  tip3           :string(255)
#  vote_type      :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  race_detail_id :bigint           not null
#
# Indexes
#
#  index_payoff_lists_on_race_detail_id  (race_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_detail_id => race_details.id)
#
require 'rails_helper'

RSpec.describe PayoffList, type: :model do
  describe 'validationの確認' do
    it 'tip1がなければerrorになること' do
      payoff_list = build(:payoff_list, tip1: nil)
      expect(payoff_list.valid?).to eq false
      expect(payoff_list.errors.messages[:tip1]).to eq(['を入力してください'])
    end
  end
end

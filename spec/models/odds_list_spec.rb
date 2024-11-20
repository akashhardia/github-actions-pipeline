# frozen_string_literal: true

# == Schema Information
#
# Table name: odds_lists
#
#  id           :bigint           not null, primary key
#  odds_count   :integer
#  vote_type    :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  odds_info_id :bigint           not null
#
# Indexes
#
#  index_odds_lists_on_odds_info_id  (odds_info_id)
#
# Foreign Keys
#
#  fk_rails_...  (odds_info_id => odds_infos.id)
#
require 'rails_helper'

RSpec.describe OddsList, type: :model do
  it 'vote_typeがなければerrorになること' do
    odds_list = build(:odds_list, vote_type: nil)
    expect(odds_list.valid?).to eq false
    expect(odds_list.errors.messages[:vote_type]).to eq(['を入力してください'])
  end
end

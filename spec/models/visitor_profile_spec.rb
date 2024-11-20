# frozen_string_literal: true

# == Schema Information
#
# Table name: visitor_profiles
#
#  id               :bigint           not null, primary key
#  address_detail   :string(255)
#  address_line     :string(255)
#  birthday         :date             not null
#  city             :string(255)
#  email            :string(255)      not null
#  family_name      :string(255)      not null
#  family_name_kana :string(255)      not null
#  given_name       :string(255)      not null
#  given_name_kana  :string(255)      not null
#  prefecture       :string(255)
#  zip_code         :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  sixgram_id       :string(255)      not null
#  ticket_id        :bigint           not null
#
# Indexes
#
#  index_visitor_profiles_on_ticket_id  (ticket_id)
#
# Foreign Keys
#
#  fk_rails_...  (ticket_id => tickets.id)
#
require 'rails_helper'

RSpec.describe VisitorProfile, type: :model do
  describe 'validationの確認' do
    it 'birthdayがなければerrorになること' do
      visitor_profile = build(:visitor_profile, birthday: nil)
      expect(visitor_profile.valid?).to eq false
      expect(visitor_profile.errors.messages[:birthday]).to eq(['を入力してください'])
    end

    it 'emailがなければerrorになること' do
      visitor_profile = build(:visitor_profile, email: nil)
      expect(visitor_profile.valid?).to eq false
      expect(visitor_profile.errors.messages[:email]).to eq(['を入力してください'])
    end

    it 'family_nameがなければerrorになること' do
      visitor_profile = build(:visitor_profile, family_name: nil)
      expect(visitor_profile.valid?).to eq false
      expect(visitor_profile.errors.messages[:family_name]).to eq(['を入力してください'])
    end

    it 'family_name_kanaがなければerrorになること' do
      visitor_profile = build(:visitor_profile, family_name_kana: nil)
      expect(visitor_profile.valid?).to eq false
      expect(visitor_profile.errors.messages[:family_name_kana]).to eq(['を入力してください'])
    end

    it 'given_nameがなければerrorになること' do
      visitor_profile = build(:visitor_profile, given_name: nil)
      expect(visitor_profile.valid?).to eq false
      expect(visitor_profile.errors.messages[:given_name]).to eq(['を入力してください'])
    end

    it 'given_name_kanaがなければerrorになること' do
      visitor_profile = build(:visitor_profile, given_name_kana: nil)
      expect(visitor_profile.valid?).to eq false
      expect(visitor_profile.errors.messages[:given_name_kana]).to eq(['を入力してください'])
    end

    it 'sixgram_idがなければerrorになること' do
      visitor_profile = build(:visitor_profile, sixgram_id: nil)
      expect(visitor_profile.valid?).to eq false
      expect(visitor_profile.errors.messages[:sixgram_id]).to eq(['を入力してください'])
    end
  end
end

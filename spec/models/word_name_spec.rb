# frozen_string_literal: true

# == Schema Information
#
# Table name: word_names
#
#  id           :bigint           not null, primary key
#  abbreviation :string(255)
#  lang         :string(255)      not null
#  name         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  word_code_id :integer          not null
#
require 'rails_helper'

RSpec.describe WordName, type: :model do
  describe 'self.get_word_name(identifier, code, lang)' do
    let(:word_lang) { 'jp' }
    let(:word_name) { create(:word_name, lang: word_lang, name: 'word_name') }
    let(:word_code) { word_name.word_code }

    it '対象のword_nameが取得できること' do
      word = described_class.get_word_name(word_code.identifier, word_code.code, 'jp')
      expect(word.name).to eq('word_name')
    end

    it '対象のword_nameがない場合はnilが返ること' do
      word = described_class.get_word_name(word_code.identifier, word_code.code, 'en')
      expect(word).to eq(nil)
    end
  end
end

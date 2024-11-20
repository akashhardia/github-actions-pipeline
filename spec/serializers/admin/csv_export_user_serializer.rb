# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CsvExportUserSerializer', type: :serializer do
  context '管理画面CSVエクスポート用ユーザーシリアライザー使用時' do
    let(:user) { create(:user, profile: profile) }
    let(:profile) { create(:profile, city: '99-99-99, test101号室', address_line: '99-99-99, test101号室', address_detail: '99-99-99, test101号室', email: 'test,@test.com') }

    it 'カンマが入ってる値はアンダーバーに変換されること' do
      serializer = Admin::CsvExportUserSerializer.new(user)
      expect(serializer.city).to eq('99-99-99_ test101号室')
      expect(serializer.address_line).to eq('99-99-99_ test101号室')
      expect(serializer.address_detail).to eq('99-99-99_ test101号室')
      expect(serializer.email).to eq('test_@test.com')
    end
  end
end

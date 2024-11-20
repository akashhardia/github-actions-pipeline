# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CsvExportOrderSerializer', type: :serializer do
  context '管理画面CSVエクスポート用オーダーシリアライザー使用時' do
    let(:campaign) { create(:campaign, title: 'テスト,キャンペーン,') }
    let(:campaign_usage) { create(:campaign_usage, campaign: campaign) }

    it 'カンマが入ってる値はアンダーバーに変換されること' do
      serializer = Admin::CsvExportOrderSerializer.new(campaign_usage.order)
      expect(serializer.campaign_title).to eq('テスト_キャンペーン_')
    end

    it 'カンマが入っていない時は何もしないこと' do
      campaign.update!(title: 'テストキャンペーン')
      serializer = Admin::CsvExportOrderSerializer.new(campaign_usage.order)
      expect(serializer.campaign_title).to eq('テストキャンペーン')
    end
  end
end

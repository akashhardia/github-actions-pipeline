# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CsvExportTicketSerializer', type: :serializer do
  context '管理画面CSVエクスポート用チケットシリアライザー使用時' do
    let(:ticket_reserve) { create(:ticket_reserve, seat_type_option: nil, order: order) }
    let(:order) { create(:order, :payment_captured, user_coupon: user_coupon) }
    let(:user_coupon) { create(:user_coupon) }

    it 'カンマが入ってる値はアンダーバーに変換されること' do
      user_coupon.coupon.template_coupon.update!(title: 'テスト,クーポン,')
      serializer = Admin::CsvExportTicketSerializer.new(ticket_reserve.ticket)
      expect(serializer.coupon_title).to eq('テスト_クーポン_')
    end

    it 'カンマが入っていない時は何もしないこと' do
      user_coupon.coupon.template_coupon.update!(title: 'テストクーポン')
      serializer = Admin::CsvExportTicketSerializer.new(ticket_reserve.ticket)
      expect(serializer.coupon_title).to eq('テストクーポン')
    end
  end
end

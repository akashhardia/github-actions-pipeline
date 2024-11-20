# frozen_string_literal: true

# == Schema Information
#
# Table name: template_coupons
#
#  id         :bigint           not null, primary key
#  note       :text(65535)
#  rate       :integer          not null
#  title      :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe TemplateCoupon, type: :model do
  describe '#title' do
    it 'titleが必須チェックでエラーになること' do
      template_coupon = build(:template_coupon, title: nil)
      expect(template_coupon.invalid?).to be true
      expect(template_coupon.errors.messages[:title]).to include('を入力してください')
    end
  end

  describe '#rate' do
    it 'rateが必須チェックでエラーになること' do
      template_coupon = build(:template_coupon, rate: nil)
      expect(template_coupon.invalid?).to be true
      expect(template_coupon.errors.messages[:rate]).to include('を入力してください')
    end

    it 'rateが0未満の場合エラーになること' do
      template_coupon = build(:template_coupon, rate: (rand(1..9) * -10))
      expect(template_coupon.invalid?).to be true
      expect(template_coupon.errors.messages[:rate]).to include('は0以上の値にしてください')
    end
  end
end

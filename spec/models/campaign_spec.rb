# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id            :bigint           not null, primary key
#  approved_at   :datetime
#  code          :string(255)      not null
#  description   :string(255)
#  discount_rate :integer          not null
#  displayable   :boolean          default(TRUE)
#  end_at        :datetime
#  start_at      :datetime
#  terminated_at :datetime
#  title         :string(255)      not null
#  usage_limit   :integer          default(9999999), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_campaigns_on_code  (code) UNIQUE
#
require 'rails_helper'

RSpec.describe Campaign, type: :model do
  let!(:old_campaign) { create(:campaign, code: 'abcdefghij') }

  context 'codeが他のレコードと重複しない場合' do
    let(:new_campaign) { build(:campaign, code: 'aaaaaaaaaa') }

    it '有効であること' do
      expect(new_campaign).to be_valid
    end
  end

  context 'codeが他のレコードと重複する場合' do
    let(:new_campaign) { build(:campaign, code: old_campaign.code) }

    it '無効であること' do
      expect(new_campaign).not_to be_valid
    end
  end

  it 'codeは大文字/小文字で別のレコードとしてそれぞれ有効である' do
    expect(build(:campaign, code: old_campaign.code.upcase)).to be_valid
  end

  context 'codeが全角文字を含む場合' do
    let(:build_campaign) { build(:campaign, code: '全角文字列') }

    it '無効である' do
      expect(build_campaign).not_to be_valid
      expect(build_campaign.errors.full_messages.first).to eq('コード値は10文字以下の半角英数字が使えます')
    end
  end

  context 'codeが前後に半角空白を含む場合' do
    let(:build_campaign) { build(:campaign, code: ' aaaaaaa ') }

    it '無効である' do
      expect(build_campaign).not_to be_valid
    end
  end

  context 'codeが文字列内に半角空白を含む場合' do
    let(:build_campaign) { build(:campaign, code: 'aaaa aaaa') }

    it '無効である' do
      expect(build_campaign).not_to be_valid
    end
  end

  context 'コード値が半角英数字10文字の場合' do
    let(:build_campaign) { build(:campaign, code: '1234567890') }

    it '有効である' do
      expect(build_campaign).to be_valid
    end
  end

  context 'コード値が半角英数字11文字の場合' do
    let(:build_campaign) { build(:campaign, code: '12345678901') }

    it '無効である' do
      expect(build_campaign).not_to be_valid
    end
  end

  context 'コード値が空白文字の場合' do
    let(:build_campaign) { build(:campaign, code: '') }

    it '無効である' do
      expect(build_campaign).not_to be_valid
    end
  end

  context '割引率が0の場合' do
    let(:build_campaign) { build(:campaign, discount_rate: 0) }

    it '有効である' do
      expect(build_campaign).to be_valid
    end
  end

  context '割引率が100の場合' do
    let(:build_campaign) { build(:campaign, discount_rate: 100) }

    it '有効である' do
      expect(build_campaign).to be_valid
    end
  end

  context '割引率が-1の場合' do
    let(:build_campaign) { build(:campaign, discount_rate: -1) }

    it '無効である' do
      expect(build_campaign).not_to be_valid
    end
  end

  context '割引率が101の場合' do
    let(:build_campaign) { build(:campaign, discount_rate: 101) }

    it '無効である' do
      expect(build_campaign).not_to be_valid
    end
  end

  context '開始日時, 承認日時, 停止日時 ≦ 予定終了日時の場合' do
    let(:build_campaign_1) { build(:campaign, start_at: '2021-1-1 0:00:00', end_at: '2021-1-1 23:59:59') }
    let(:build_campaign_2) { build(:campaign, approved_at: '2021-1-1 0:00:00', end_at: '2021-1-1 23:59:59') }
    let(:build_campaign_3) { build(:campaign, terminated_at: '2021-1-1 0:00:00', end_at: '2021-1-1 23:59:59') }

    it '有効である' do
      expect(build_campaign_1).to be_valid
      expect(build_campaign_2).to be_valid
      expect(build_campaign_3).to be_valid
    end
  end

  context '開始日時＞予定終了日時の場合' do
    let(:build_campaign) { build(:campaign, start_at: '2021-1-2 0:00:00', end_at: '2021-1-1 23:59:59') }

    it '無効である' do
      expect(build_campaign).not_to be_valid
    end
  end

  context '承認日時＞予定終了日時の場合' do
    let(:build_campaign) { build(:campaign, approved_at: '2021-1-2 0:00:00', end_at: '2021-1-1 23:59:59') }

    it '無効である' do
      expect(build_campaign).not_to be_valid
    end
  end

  context '停止日時＞予定終了日時の場合' do
    let(:build_campaign) { build(:campaign, terminated_at: '2021-1-2 0:00:00', end_at: '2021-1-1 23:59:59') }

    it '無効である' do
      expect(build_campaign).not_to be_valid
    end
  end
end

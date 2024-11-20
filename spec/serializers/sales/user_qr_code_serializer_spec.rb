# frozen_string_literal: true

require 'rails_helper'

describe Sales::UserQrCodeSerializer, type: :serializer do
  let(:user) { create(:user) }

  it 'シリアライズされたJSONが作成されること' do
    serializer = described_class.new(user)
    expect(serializer.to_json).to eq(user.to_json(only: :qr_user_id))
  end
end

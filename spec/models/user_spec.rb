# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                       :bigint           not null, primary key
#  deleted_at               :datetime
#  email_auth_code          :string(255)
#  email_auth_expired_at    :datetime
#  email_verified           :boolean          default(FALSE), not null
#  unsubscribe_mail_sent_at :datetime
#  unsubscribe_uuid         :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  qr_user_id               :string(255)
#  sixgram_id               :string(255)      not null
#
# Indexes
#
#  index_users_on_sixgram_id  (sixgram_id) UNIQUE
#
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validationの確認' do
    it '正常にuserが作成されること' do
      create(:user)
      expect(described_class.count).to eq 1
    end

    it 'sixgram_idがなければerrorになること' do
      user = described_class.new
      expect(user.valid?).to eq false
    end

    it 'sixgram_idがユニークでなければerrorになること' do
      user1 = create(:user)
      user = described_class.new(sixgram_id: user1.sixgram_id)
      expect(user.valid?).to eq false
    end
  end

  describe 'DBの確認' do
    it 'sixgram_idにユニーク制約がかかっていること' do
      user1 = create(:user)
      user = described_class.new(sixgram_id: user1.sixgram_id)
      expect { user.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'qr_user_id_generateメソッドの確認' do
    it 'qr_user_idが作成されること' do
      user = create(:user, qr_user_id: nil)
      expect { user.qr_user_id_generate! }.to change { user.reload.qr_user_id }
    end
  end

  describe 'unsubscribed? メソッドの確認' do
    it '退会済みの場合trueが返る' do
      user = create(:user)
      expect(user.unsubscribed?).to eq false
    end

    it '退会済みでない場合falseが返る' do
      user = create(:user, deleted_at: Time.zone.now)
      expect(user.unsubscribed?).to eq true
    end
  end
end

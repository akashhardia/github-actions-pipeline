# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnsubscribedUserHandler do
  describe '#delete_personal_info' do
    subject(:delete_personal_info) { described_class.delete_personal_info([user1, user2]) }

    context '退会ユーザーのみで実行した場合' do
      let(:user1) { create(:user, :with_profile, sixgram_id: '111', deleted_at: Time.zone.now) }
      let(:user2) { create(:user, :with_profile, sixgram_id: '222', deleted_at: Time.zone.now) }

      it '退会ユーザーのsixgram_idを更新すること' do
        delete_personal_info
        expect(user1.reload.sixgram_id).to eq("unsubscribed_user_#{user1.id}_111")
        expect(user2.reload.sixgram_id).to eq("unsubscribed_user_#{user2.id}_222")
      end

      it '退会ユーザーのprofileのカラムを更新すること' do
        delete_personal_info
        profiles = Profile.all
        expect(profiles.pluck(:family_name).uniq).to eq(['退会済み'])
        expect(profiles.pluck(:given_name).uniq).to eq(['ユーザー'])
        expect(profiles.pluck(:family_name_kana).uniq).to eq(['タイカイズミ'])
        expect(profiles.pluck(:given_name_kana).uniq).to eq(['ユーザー'])
        expect(profiles.pluck(:birthday).uniq).to eq([Date.new(1000, 1, 1)])
        expect(profiles.pluck(:email).uniq).to eq(['unsubscribed_user@example.com'])
        expect(profiles.pluck(:zip_code).uniq).to eq(['0000000'])
        expect(profiles.pluck(:prefecture).uniq).to eq(['退会'])
        expect(profiles.pluck(:city).uniq).to eq(['退会'])
        expect(profiles.pluck(:address_line).uniq).to eq(['退会'])
        expect(profiles.pluck(:phone_number).uniq).to eq([nil])
        expect(profiles.pluck(:address_detail).uniq).to eq([nil])
        expect(profiles.pluck(:auth_code).uniq).to eq([nil])
        expect(profiles.pluck(:mailmagazine).uniq).to eq([false])
      end
    end

    context '未退会ユーザーが含まれている場合' do
      let(:user1) { create(:user, :with_profile, sixgram_id: '111', deleted_at: nil) }
      let(:user2) { create(:user, :with_profile, sixgram_id: '222', deleted_at: Time.zone.now) }

      it '未退会ユーザーのsixgram_idを変更しないこと' do
        expect { delete_personal_info }.not_to change { user1.reload.sixgram_id }
      end

      it '退会ユーザーのsixgram_idを更新すること' do
        delete_personal_info
        expect(user2.reload.sixgram_id).to eq("unsubscribed_user_#{user2.id}_222")
      end

      it '未退会ユーザーのprofileのカラムを更新しないこと' do
        expect { delete_personal_info }.to not_change { user1.profile.reload.attributes }
      end

      it '退会ユーザーのprofileのカラムを更新すること' do
        delete_personal_info
        user2_profile = user2.reload.profile
        expect(user2_profile.family_name).to eq('退会済み')
        expect(user2_profile.given_name).to eq('ユーザー')
        expect(user2_profile.family_name_kana).to eq('タイカイズミ')
        expect(user2_profile.given_name_kana).to eq('ユーザー')
        expect(user2_profile.birthday).to eq(Date.new(1000, 1, 1))
        expect(user2_profile.email).to eq('unsubscribed_user@example.com')
        expect(user2_profile.zip_code).to eq('0000000')
        expect(user2_profile.prefecture).to eq('退会')
        expect(user2_profile.city).to eq('退会')
        expect(user2_profile.address_line).to eq('退会')
        expect(user2_profile.phone_number).to eq(nil)
        expect(user2_profile.address_detail).to eq(nil)
        expect(user2_profile.auth_code).to eq(nil)
        expect(user2_profile.mailmagazine).to eq(false)
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'
require 'rake_helper'

describe 'unsubscribed_user raketask' do # rubocop:disable RSpec/DescribeClass
  describe 'unsubscribed_user:delete_personal_info' do
    let(:delete_personal_info_task) { Rake.application['unsubscribed_user:delete_personal_info'] }

    context '退会後、11日以上経過しているユーザーが存在する場合' do
      before do
        create(:user, :with_profile, sixgram_id: 'unsubscribed_user_333', deleted_at: Time.zone.now - 11.days)
      end

      let!(:user1) { create(:user, :with_profile, sixgram_id: '111', deleted_at: Time.zone.now - 11.days) }

      it 'ユーザー情報が未削除のユーザーのみUnsubscribedUserHandler.delete_personal_infoが実行されること' do
        allow(UnsubscribedUserHandler).to receive(:delete_personal_info)
        delete_personal_info_task.invoke
        expect(UnsubscribedUserHandler).to have_received(:delete_personal_info).once.with([user1])
      end
    end

    context '退会後、11日以上経過しているユーザーが存在しない場合' do
      before do
        create(:user, :with_profile, sixgram_id: '111', deleted_at: Time.zone.now)
        create(:user, :with_profile, sixgram_id: '222', deleted_at: Time.zone.now - 10.days)
      end

      it 'UnsubscribedUserHandler.delete_personal_infoが実行されないこと' do
        allow(UnsubscribedUserHandler).to receive(:delete_personal_info)
        delete_personal_info_task.invoke
        expect(UnsubscribedUserHandler).not_to have_received(:delete_personal_info)
      end
    end
  end
end

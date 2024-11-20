# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/EmptyExampleGroup
describe NgUserChecker, :sales_jwt_mock, type: :model do
  # TODO: NGユーザーチェックスキップ
  # describe '#validate!' do
  #   subject(:validate!) do
  #     ng_user_checker = described_class.new(sixgram_access_token)
  #     ng_user_checker.validate!
  #   end

  #   context '有効なユーザーの場合' do
  #     it 'NgUserErrorが発生しないこと' do
  #       expect { validate! }.not_to raise_error
  #     end
  #   end

  #   context '6gramで反社ユーザーとしてマークされている場合' do
  #     let(:sales_jwt_mock_user_sixgram_id) { '09000010002' }

  #     it 'NgUserErrorが発生すること' do
  #       expect { validate! }.to raise_error(NgUserError)
  #     end
  #   end

  #   context '6gramでBANされている場合' do
  #     let(:sales_jwt_mock_user_sixgram_id) { '09000020002' }

  #     it 'NgUserErrorが発生すること' do
  #       expect { validate! }.to raise_error(NgUserError)
  #     end
  #   end

  #   context 'すでに退会しているユーザーの場合' do
  #     let(:sales_jwt_mock_user_sixgram_id) { '08012345678' }

  #     it 'NgUserErrorが発生すること' do
  #       create(:user, :with_profile, sixgram_id: sales_jwt_mock_user_sixgram_id)
  #       User.update_all(deleted_at: Time.zone.now)
  #       expect { validate! }.to raise_error(NgUserError)
  #     end
  #   end

  # TODO: validate!が有効になった際にあわせて修正してください。
  #   context '退会していないユーザーの場合' do
  #     let(:sales_jwt_mock_user_sixgram_id) { '08012345678' }

  #     it 'NgUserErrorが発生しないこと' do
  #       create(:user, :with_profile, sixgram_id: sales_jwt_mock_user_sixgram_id)
  #       expect { validate! }.not_to raise_error
  #     end
  #   end
  # end
end
# rubocop:enable RSpec/EmptyExampleGroup

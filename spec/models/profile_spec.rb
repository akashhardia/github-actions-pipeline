# frozen_string_literal: true

# == Schema Information
#
# Table name: profiles
#
#  id               :bigint           not null, primary key
#  address_detail   :string(255)
#  address_line     :string(255)
#  auth_code        :text(65535)
#  birthday         :date             not null
#  city             :string(255)
#  email            :string(255)      not null
#  family_name      :string(255)      not null
#  family_name_kana :string(255)      not null
#  given_name       :string(255)      not null
#  given_name_kana  :string(255)      not null
#  mailmagazine     :boolean          default(FALSE), not null
#  ng_user_check    :boolean          default(TRUE), not null
#  phone_number     :string(255)
#  prefecture       :string(255)
#  zip_code         :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Profile, type: :model do
  let(:profile) { create(:profile) }

  describe '#scoped_serializer' do
    subject(:scoped_serialize) { profile.scoped_serializer(scope) }

    let(:scope) { :given_name }

    it '指定されたfieldの値しかシリアライズされないこと' do
      expect(scoped_serialize.serializable_hash.keys).to eq([:given_name])
    end
  end

  describe '空白のトリムの処理の確認' do
    let(:profile2) { create(:profile, family_name: ' 山　田 ', given_name: '　花 子 ', family_name_kana: ' ヤ マ ダ　', given_name_kana: ' ハ ナ コ ') }

    it 'family_name' do
      expect(profile2.family_name).to eq('山田')
      expect(profile2.given_name).to eq('花子')
      expect(profile2.family_name_kana).to eq('ヤマダ')
      expect(profile2.given_name_kana).to eq('ハナコ')
    end
  end

  describe 'profile作成' do
    describe 'addresses' do
      subject(:build_profile) { build(:profile, addresses) }

      context 'すべての住所が入力されている場合' do
        let(:addresses) do
          {
            zip_code: '1234567',
            prefecture: '東京都😀',
            city: 'city',
            address_line: 'address_line'
          }
        end

        it 'バリデーションエラーが発生しないこと' do
          expect(build_profile.valid?).to be true
        end
      end

      context '一部の住所が入力されていない場合' do
        let(:addresses) do
          {
            zip_code: '1234567',
            prefecture: '東京都',
            city: '',
            address_line: 'address_line'
          }
        end

        it 'バリデーションエラーが発生すること' do
          expect(build_profile.valid?).to be false
        end
      end

      context 'すべての住所が入力されていない場合' do
        let(:addresses) do
          {
            zip_code: '',
            prefecture: '',
            city: '',
            address_line: ''
          }
        end

        it 'バリデーションエラーが発生すること' do
          expect(build_profile.valid?).to be false
        end
      end

      context '他のvalidationに影響してないか確認' do
        let(:addresses) do
          {
            zip_code: '1',
            prefecture: '東京都',
            city: 'city',
            address_line: 'address_line'
          }
        end

        it '郵便番号長のエラーが発生すること' do
          expect(build_profile.valid?).to be false
          expect(build_profile.errors.details[:zip_code][0][:error]).to eq(:invalid)
          expect(build_profile.errors.full_messages.first).to eq('郵便番号は半角数字7ケタで入力して下さい。')
        end
      end
    end

    describe 'phone_number' do
      subject(:build_profile) { build(:profile, phone_number) }

      context '正しいフォーマットの電話番号が入力されている場合' do
        let(:phone_number) { { phone_number: '09090909090' } }

        it 'バリデーションエラーが発生しないこと' do
          expect(build_profile.valid?).to be true
        end
      end

      context '１２桁の電話番号が入力されている場合' do
        let(:phone_number) { { phone_number: '023790909090' } }

        it 'バリデーションエラーが発生すること' do
          expect(build_profile.valid?).to be false
        end
      end

      context '数字以外の電話番号が入力されている場合' do
        let(:phone_number) { { phone_number: '09090909Z90' } }

        it 'バリデーションエラーが発生すること' do
          expect(build_profile.valid?).to be false
        end
      end

      context '０始まりではない電話番号が入力されている場合' do
        let(:phone_number) { { phone_number: '19090909090' } }

        it 'バリデーションエラーが発生すること' do
          expect(build_profile.valid?).to be false
        end
      end
    end

    describe 'email' do
      subject(:build_profile) { build(:profile, email) }

      context '正しいフォーマットの電話番号が入力されている場合' do
        let(:email) { { email: 'test@test.com' } }

        it 'バリデーションエラーが発生しないこと' do
          expect(build_profile.valid?).to be true
        end
      end

      context 'emailの中に2byte文字が入力されている場合' do
        let(:email) { { email: 'te😀st@test.com' } }

        it 'バリデーションエラーが発生すること' do
          expect(build_profile.valid?).to be false
          expect(build_profile.errors.full_messages.first).to eq('メールアドレスを正しく入力してください。')
        end
      end

      context 'emailの中に全角のスペースが入力されている場合' do
        let(:email) { { email: 'tes　t@test.com' } }

        it 'バリデーションエラーが発生すること' do
          expect(build_profile.valid?).to be false
          expect(build_profile.errors.full_messages.first).to eq('メールアドレスを正しく入力してください。')
        end
      end
    end

    describe 'family_name_kana' do
      subject(:build_profile) { build(:profile, family_name_kana) }

      context '正しいフォーマットのフリガナ（セイ）が入力されている場合' do
        let(:family_name_kana) { { family_name_kana: 'セイ' } }

        it 'バリデーションエラーが発生しないこと' do
          expect(build_profile.valid?).to be true
        end
      end

      context 'ひらがなが入力されている場合' do
        let(:family_name_kana) { { family_name_kana: 'せい' } }

        it 'バリデーションエラーが発生すること' do
          expect(build_profile.valid?).to be false
          expect(build_profile.errors.full_messages.first).to eq('フリガナ（セイ）は全角カタカナで入力して下さい。')
        end
      end
    end

    describe 'given_name_kana' do
      subject(:build_profile) { build(:profile, given_name_kana) }

      context '正しいフォーマットのフリガナ（メイ）が入力されている場合' do
        let(:given_name_kana) { { given_name_kana: 'メイ' } }

        it 'バリデーションエラーが発生しないこと' do
          expect(build_profile.valid?).to be true
        end
      end

      context '半角カナが入力されている場合' do
        let(:given_name_kana) { { given_name_kana: 'ﾒｲ' } }

        it 'バリデーションエラーが発生すること' do
          expect(build_profile.valid?).to be false
          expect(build_profile.errors.full_messages.first).to eq('フリガナ（メイ）は全角カタカナで入力して下さい。')
        end
      end
    end

    describe 'prefecture' do
      subject(:build_profile) { build(:profile, prefecture) }

      context 'prefectureが選択されている場合' do
        let(:prefecture) { { prefecture: '東京都' } }

        it 'バリデーションエラーが発生しないこと' do
          expect(build_profile.valid?).to be true
        end
      end

      context 'prefectureが選択されていない場合' do
        let(:prefecture) { { prefecture: '' } }

        it 'バリデーションエラーが発生すること' do
          expect(build_profile.valid?).to be false
          expect(build_profile.errors.full_messages.first).to eq('都道府県を選択してください。')
        end
      end
    end

    describe 'birthday' do
      subject(:build_profile) { build(:profile, birthday) }

      context 'birthdayが選択されている場合' do
        let(:birthday) { { birthday: Time.zone.now - 20.years } }

        it 'バリデーションエラーが発生しないこと' do
          expect(build_profile.valid?).to be true
        end
      end

      context 'birthdayが選択されていない場合' do
        let(:birthday) { { birthday: '' } }

        it 'バリデーションエラーが発生すること' do
          expect(build_profile.valid?).to be false
          expect(build_profile.errors.full_messages.first).to eq('生年月日を選択してください。')
        end
      end
    end

    describe 'agreement' do
      subject(:build_profile) { build(:profile) }

      context 'agreementが選択されている場合' do
        before { build_profile.agreement = true }

        it 'バリデーションエラーが発生しないこと' do
          expect(build_profile.valid?(:confirm)).to be true
        end
      end

      context 'agreementが選択されていない場合' do
        before { build_profile.agreement = false }

        it 'バリデーションエラーが発生すること' do
          expect(build_profile.valid?(:confirm)).to be false
          expect(build_profile.errors.full_messages.first).to eq('「上記規約に同意する」を選択してください。')
        end
      end
    end
  end
end

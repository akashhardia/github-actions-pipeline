# frozen_string_literal: true

require 'rails_helper'

describe SixgramPayment::Service do
  describe '#charge_status' do
    subject(:charge_status) { described_class.charge_status(charge_id) }

    context 'デフォルト' do
      let(:charge_id) { 'charge_id' }

      it '決済済み、オーソリ済みステータスが返却される' do
        result = charge_status
        expect(result.ok?).to be true
        expect(result['status']).to eq('succeeded')
        expect(result['captured']).to be true
        expect(result['authorized']).to be true
      end
    end

    context '処理中' do
      let(:charge_id) { '211111' }

      it '処理中のステータスが返却される' do
        result = charge_status
        expect(result.ok?).to be true
        expect(result['status']).to eq('processing')
      end
    end

    context '失敗' do
      let(:charge_id) { '211112' }

      it '失敗のステータスが返却される' do
        result = charge_status
        expect(result.ok?).to be true
        expect(result['status']).to eq('failed')
      end
    end

    context 'オーソリ未処理' do
      let(:charge_id) { '211114' }

      it 'authorizedがfalseであること' do
        result = charge_status
        expect(result.ok?).to be true
        expect(result['captured']).to be false
        expect(result['authorized']).to be false
      end
    end
  end

  describe '#capture' do
    subject(:capture) { described_class.capture(charge_id, amount) }

    let(:amount) { 200 }

    context 'デフォルト' do
      let(:charge_id) { 'charge_id' }

      it '成功ステータスが返却される' do
        result = capture
        expect(result.ok?).to be true
        expect(result['status']).to eq('succeeded')
        expect(result['captured']).to be true
      end

      it 'リトライしていないこと' do
        allow(SixgramPayment::MockPayment).to receive(:find_mock).and_return(JSON.parse({ ok?: true, response: { code: '200' }, status: 'succeeded', captured: true }.to_json, object_class: OpenStruct))
        result = capture
        expect(result.ok?).to be true
        expect(SixgramPayment::MockPayment).to have_received(:find_mock).once
      end
    end

    context '支払確定処理中' do
      let(:charge_id) { '212111' }

      it '処理中のステータスが返却される' do
        result = capture
        expect(result.ok?).to be true
        expect(result['status']).to eq('processing')
      end
    end

    context '支払確定失敗' do
      let(:charge_id) { '212112' }

      it '失敗のステータスが返却される' do
        result = capture
        expect(result.ok?).to be true
        expect(result['status']).to eq('failed')
      end
    end

    context '支払確定済み' do
      let(:charge_id) { '412111' }

      it 'エラーは発生しないが、errorコードは返されること' do
        result = capture
        expect(result.ok?).to be false
        expect(result['error']).to eq('already_captured')
      end
    end

    context '返金処理済み' do
      let(:charge_id) { '412112' }

      it 'エラーが発生すること' do
        expect { capture }.to raise_error(CustomError)
      end
    end

    context 'チャージバック済み' do
      let(:charge_id) { '412113' }

      it 'エラーが発生すること' do
        expect { capture }.to raise_error(CustomError)
      end
    end

    context '決済確定期限切れ' do
      let(:charge_id) { '412114' }

      it 'エラーが発生すること' do
        expect { capture }.to raise_error(CustomError)
      end
    end

    context '決済に失敗した' do
      let(:charge_id) { '412115' }

      it 'エラーが発生すること' do
        expect { capture }.to raise_error(CustomError)
      end
    end

    context '存在しない決済を指定した' do
      let(:charge_id) { '412116' }

      it 'エラーが発生すること' do
        expect { capture }.to raise_error(CustomError)
      end
    end

    context 'internal_server_errorを指定した' do
      let(:charge_id) { '412199' }

      it 'リトライを指定の回数行っていること' do
        error_detail = 'status: 500, code: internal_server_error, context: capture, description: , decline_code: '
        allow(SixgramPayment::MockPayment).to receive(:find_mock).and_return(JSON.parse({ ok?: false, response: { code: '500' }, error: 'internal_server_error' }.to_json, object_class: OpenStruct))

        expect { capture }.to raise_error(FatalSixgramPaymentError, "決済中にエラーが発生しました #{error_detail}")
        expect(SixgramPayment::MockPayment).to have_received(:find_mock).exactly(3).times
      end
    end
  end

  describe '#refund' do
    subject(:refund) { described_class.refund(charge_id) }

    context 'デフォルト' do
      let(:charge_id) { 'charge_id' }

      it '成功ステータスが返却される' do
        result = refund
        expect(result.ok?).to be true
        expect(result['amount_refunded'].present?).to be true
      end
    end

    context '全額返金済' do
      let(:charge_id) { '413111' }

      it 'エラーが発生すること' do
        expect { refund }.to raise_error(CustomError)
      end
    end

    context 'チャージバック済' do
      let(:charge_id) { '413112' }

      it 'エラーが発生すること' do
        expect { refund }.to raise_error(CustomError)
      end
    end

    context '決済確定期限を超えた' do
      let(:charge_id) { '413113' }

      it 'エラーが発生すること' do
        expect { refund }.to raise_error(CustomError)
      end
    end

    context '存在しない決済を指定した' do
      let(:charge_id) { '413114' }

      it 'エラーが発生すること' do
        expect { refund }.to raise_error(CustomError)
      end
    end
  end
end

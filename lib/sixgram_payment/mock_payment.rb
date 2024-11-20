# frozen_string_literal: true

module SixgramPayment
  # Mock動作のみ
  # APIでNG系のレスポンスが返ってくる決済をここで定義する
  class MockPayment
    extend MockResponse

    class << self
      def find_mock(method_name, charge_id)
        response = mock_response[method_name][charge_id].presence || mock_response[method_name][:default]

        JSON.parse(response.to_json, object_class: OpenStruct)
      end

      private

      def mock_response
        {
          charge_status: {
            default: { **ok, status: 'succeeded', captured: true, authorized: true },
            '211111' => { **ok, status: 'processing', captured: false, authorized: true },
            '211112' => { **ok, status: 'failed', captured: false, authorized: true },
            '211113' => { **ok, status: 'canceled', captured: false, authorized: true },
            '211114' => { **ok, captured: false, authorized: false },
            '211115' => { **not_found, error: 'resource_not_found', error_description: 'resource not found' }
          },
          capture: {
            default: { **ok, status: 'succeeded', captured: true },
            '212111' => { **ok, status: 'processing' },
            '212112' => { **ok, status: 'failed' },
            '212113' => { **ok, status: 'canceled' },
            '212114' => { **ok, status: 'failed', captured: false },
            '412111' => { **bad_request, error: 'already_captured', error_description: 'already captured', object_id: '412111' },
            '412112' => { **bad_request, error: 'already_refunded', description: '返金済のChargeが指定されました' },
            '412113' => { **bad_request, error: 'disputed', description: 'チャージバック済のChargeが指定されました' },
            '412114' => { **bad_request, error: 'expired_for_capture', description: '決済確定期限を超えたChargeが指定されました' },
            '412115' => { **bad_request, error: 'card_declined', description: '決済に失敗しました', decline_code: 'カードが有効期限切れです' },
            '412116' => { **not_found, error: 'resource_not_found', description: '存在しないChargeが指定されました' },
            '412199' => { **internal_server_error, error: 'internal_server_error' }
          },
          refund: {
            default: { **ok, amount_refunded: 2000 },
            '413111' => { **bad_request, error: 'already_refunded' },
            '413112' => { **bad_request, error: 'disputed' },
            '413113' => { **bad_request, error: 'expired_for_refund' },
            '413114' => { **not_found, error: 'resource_not_found' }
          }
        }
      end
    end
  end
end

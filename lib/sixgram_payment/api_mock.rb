# frozen_string_literal: true

module SixgramPayment
  # sixgram_payment api fetcher (mock)
  class ApiMock < MockPayment
    class << self
      # 支払取得API
      def charge_status(charge_id)
        find_mock(__method__, charge_id)
      end

      # 支払確定API
      def capture(charge_id, _amount)
        find_mock(__method__, charge_id)
      end

      # 返金API
      def refund(charge_id)
        find_mock(__method__, charge_id)
      end
    end
  end
end

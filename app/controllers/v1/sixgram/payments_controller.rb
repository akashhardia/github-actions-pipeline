# frozen_string_literal: true

module V1
  module Sixgram
    # 6gramの決済情報(Charge)更新Webhook受付API
    class PaymentsController < ApplicationController
      # before_action :webhook_auth
      # 決済処理後などにChargeオブジェクトが更新された場合にコールされる
      # 現状ではorders_controller#create #captureで完結する想定なので特に何もしていない
      # 決済失敗などのステータスが飛んできた場合に特殊対応が必要となったら処理を追加してください
      def update
        # PaymentProcessor.update_charge(params[:charge_id])
        head :ok
      end
    end
  end
end

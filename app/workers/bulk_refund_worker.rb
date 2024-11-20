# frozen_string_literal: true

# 一括返金非同期処理
class BulkRefundWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(args)
    seat_sale = SeatSale.find(args)
    orders = seat_sale.orders.includes(:tickets, :payment).where(tickets: { status: 'sold' })
    refund_ids = orders.where(payment: { payment_progress: 'captured' }).distinct.ids

    # requesting_paymentの場合は、authorizedがtrueの場合のみ返金処理をする
    orders.where(payment: { payment_progress: 'requesting_payment' }).distinct.each do |order|
      result = ApiProvider.new_system.charge_status(order.payment.charge_id)

      # 問い合わせが失敗した場合は、返金失敗時と同様にエラーメッセージを格納する
      if result['error'].present?
        order.update(refund_error_message: result['error_description'])
        next
      end

      # 'authorized'がfalseの場合は、返金処理はしない
      next if result['authorized'] == false

      # 返金対象であれば、リストに追加
      refund_ids << order.id
    end

    refund_ids.each do |order_id|
      PaymentTransactor.refund(order_id)
    rescue StandardError => e
      # エラーの場合はエラーフラグON、エラーメッセージ格納
      Order.find(order_id).update(refund_error_message: e)
    end
    seat_sale.update(refund_end_at: Time.zone.now)
  end
end

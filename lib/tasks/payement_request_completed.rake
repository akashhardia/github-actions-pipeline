# frozen_string_literal: true

namespace :payment do
  desc '決済がオーソリー完了で放置されているチケットの決済確定をする'
  task request_completed: :environment do |task|
    Rails.logger.info(format('Rake task "%<task_name>s" STARTED!!', task_name: task.name))
    errors = []
    payments = Payment.joins(order: :seat_sale).includes(order: :user)
                      .where('payments.created_at < ?', Time.zone.now - 45.minutes)
                      .where(payment_progress: 'requesting_payment')
                      .where('seat_sales.sales_end_at > ? ', Date.yesterday)
    payments.each do |payment|
      Rails.logger.info "Started updating payment_id: #{payment.id}, payment_progress: #{payment.payment_progress}"
      user = payment.order.user
      cart = Cart.new(user)
      charge_id = payment.charge_id

      # paymentのcharge_idとcartのcharge_idとcharge_idが一致しない場合は返金処理リクエストをし、手続き失敗（failed_request）にする
      unless charge_id == cart.charge_id
        payment.failed_request!
        refund_result = NewSystem::Service.refund(payment.charge_id)
        errors << { error_class: StandardError, message: refund_result, payment_id: payment.id } unless refund_result[:ok?]
        Rails.logger.info "Finished updating payment_id: #{payment.id}, payment_progress: #{payment.payment_progress}"

        next
      end

=begin
      lock_key = "capture2_#{charge_id}"
      raise StandardError, I18n.t('custom_errors.orders.fail_to_purchase', charge_id: charge_id) unless Redis.current.setnx(lock_key, 1) # ロック作成と有無を確認 setnx(key, value) => Boolean

      Rails.logger.info "Locked charge_id：#{charge_id}" # lock成功時にcharge_idをログに吐く
      Redis.current.expire(lock_key, 60) # デッドロック防止に期限つける（１分間）

      result = PaymentTransactor.request_completed(user, charge_id)

      if result[:error] == 'failed_request'
        refund_result = NewSystem::Service.refund(payment.charge_id)
        errors << { error_class: StandardError, message: refund_result, payment_id: payment.id } unless refund_result[:ok?]
      elsif result[:info] == 'already_captured' && (payment.waiting_capture? || payment.requesting_payment?)
        ActiveRecord::Base.transaction do
          payment.update!(captured_at: Time.zone.now, payment_progress: :captured)
          payment.order.ticket_reserves.each do |ticket_reserve|
            ticket_reserve.ticket.update!(user: user, qr_ticket_id: AdmissionUuid.generate_uuid, status: :sold, purchase_ticket_reserve_id: ticket_reserve.id, current_ticket_reserve_id: ticket_reserve.id)
          end
        end

        ActiveRecord::Base.transaction do
          NotificationMailer.send_purchase_completion_notification_to_user(user, payment.order.tickets.to_a, payment.order.total_price).deliver_later
        end
      end
=end

      Rails.logger.info "Finished payment_id: #{payment.id}, payment_progress: #{payment.payment_progress}"
    rescue StandardError => e
      Rails.logger.info "Error occured while updating payment_id: #{payment.id}, payment_progress: #{payment.payment_progress}"
      errors << { error_class: e.class, message: e.message, payment_id: payment.id }
    end

    raise StandardError, errors.to_s if errors.present?

    Rails.logger.info(format('Rake task "%<task_name>s" ALL DONE!!', task_name: task.name))
  end
end

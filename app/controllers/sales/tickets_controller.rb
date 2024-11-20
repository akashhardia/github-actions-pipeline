# frozen_string_literal: true

module Sales
  # チケットコントローラー
  class TicketsController < ApplicationController
    skip_before_action :require_login!, only: [:receive_ticket]
    before_action :ng_user_check, only: [:transfer, :receive, :receive_admin_ticket]
    before_action :set_ticket, only: [:transfer, :cancel]
    before_action :check_ticket_ownership, only: [:transfer, :cancel]


    # 譲渡用UUIDの生成（ticket.rb経由でticketsテーブルをupdate）
    # /sales/ticket_reserves/:id/transfer
    def transfer
      @ticket.sold_ticket_uuid_generate!

      head :ok
    end

    # 譲渡された情報確認
    # 譲渡用UUIDをもとにチケット情報を取得
    # /sales/tickets/:transfer_uuid/receive
    def receive_ticket
      receive_ticket = Ticket.find_by!(transfer_uuid: params['transfer_uuid'])
      render json: receive_ticket, serializer: Sales::ReceivedTicketSerializer, key_transform: :camel_lower
    end

    # 譲渡受け取り
    # /sales/tickets/:transfer_uuid/receive
    def receive
      ticket = Ticket.find_by!(transfer_uuid: params['transfer_uuid'])
      transfer_user = User.find(ticket.user_id)

      ticket.receive_transfer_ticket!(current_user)

      # 譲渡元のユーザーに譲渡完了のメールを送信
      NotificationMailer.send_transfer_notification_to_user(transfer_user, ticket).deliver_later unless transfer_user.unsubscribed?

      head :ok
    end

    # 管理画面譲渡の受け取り
    # /sales/tickets/:transfer_uuid/receive_admin_ticket
    def receive_admin_ticket
      ticket = Ticket.includes(seat_type: :seat_sale).find_by!(transfer_uuid: params['transfer_uuid'])
      ticket.receive_admin_transfer_ticket!(current_user)

      head :ok
    end

    # チケット譲渡処理の中止
    # ticket.rbを通してticketsテーブルをupdateしている
    # /sales/ticket_reserves/:id/transfer_cancel
    def cancel
      @ticket.cancel_transfer!

      head :ok
    end


    # ここ以降は上記のメソッドが使うメソッドであり、APIではない
    private

    def set_ticket
      raise TransferTicketError, I18n.t('custom_errors.ticket.ticket_reserve_not_found') if TicketReserve.find_by(id: params[:id]).nil?

      @ticket = current_user.ticket_reserves.find(params[:id]).ticket
    end

    def check_ticket_ownership
      raise TransferTicketError, I18n.t('custom_errors.ticket.ownership_not_match') unless @ticket.user_id == current_user.id
    end
  end
end

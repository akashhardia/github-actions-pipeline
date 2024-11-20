# frozen_string_literal: true

module Admin
  # 管理画面用チケット詳細譲渡ステータスSerializer
  class TicketReserveStatusSerializer < ActiveModel::Serializer
    attributes :id, :transfer_at, :order_id, :seat_type_option_id, :transfer_from_user_id, :transfer_to_user_id, :returned_at, :created_at, :updated_at

    delegate :returned_at, to: :order

    private

    def order
      object.order
    end
  end
end

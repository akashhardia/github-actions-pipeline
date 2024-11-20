# frozen_string_literal: true

# == Schema Information
#
# Table name: ticket_reserves
#
#  id                         :bigint           not null, primary key
#  transfer_at                :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  next_ticket_reserve_id     :bigint
#  order_id                   :bigint           not null
#  previous_ticket_reserve_id :bigint
#  seat_type_option_id        :bigint
#  ticket_id                  :bigint
#  transfer_from_user_id      :integer
#  transfer_to_user_id        :integer
#
# Indexes
#
#  fk_rails_42a1e40625                           (previous_ticket_reserve_id)
#  fk_rails_8e89099d87                           (next_ticket_reserve_id)
#  index_ticket_reserves_on_order_id             (order_id)
#  index_ticket_reserves_on_seat_type_option_id  (seat_type_option_id)
#  index_ticket_reserves_on_ticket_id            (ticket_id)
#
# Foreign Keys
#
#  fk_rails_...  (next_ticket_reserve_id => ticket_reserves.id)
#  fk_rails_...  (order_id => orders.id)
#  fk_rails_...  (previous_ticket_reserve_id => ticket_reserves.id)
#  fk_rails_...  (seat_type_option_id => seat_type_options.id)
#  fk_rails_...  (ticket_id => tickets.id)
#
class TicketReserve < ApplicationRecord
  belongs_to :order
  belongs_to :ticket
  belongs_to :seat_type_option, optional: true
  belongs_to :next_ticket_reserve, optional: true, class_name: 'TicketReserve'
  belongs_to :previous_ticket_reserve, optional: true, class_name: 'TicketReserve'

  # Validations -----------------------------------------------------------------------------------
  validates :ticket_id, presence: true

  scope :admission_ticket, ->(user) { joins(order: :seat_sale).where('orders.user_id = ?', user.id).where('seat_sales.admission_close_at > ?', Time.zone.now) }
  scope :not_transfer_ticket_reserve, -> { includes(seat_type_option: :template_seat_type_option, order: :payment).where(transfer_at: nil) }
  scope :filter_ticket_reserves, -> { eager_load(:order, order: :payment).where(orders: { order_type: [:transfer, :admin_transfer] }).or(eager_load(:order, order: :payment).where(orders: { order_type: :purchase, payments: { payment_progress: :captured } })) }
end

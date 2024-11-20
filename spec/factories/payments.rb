# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id               :bigint           not null, primary key
#  captured_at      :datetime
#  payment_progress :integer          default("requesting_payment"), not null
#  refunded_at      :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  charge_id        :string(255)      not null
#  order_id         :bigint           not null
#
# Indexes
#
#  index_payments_on_order_id  (order_id)
#
# Foreign Keys
#
#  fk_rails_...  (order_id => orders.id)
#
FactoryBot.define do
  factory :payment do
    order
    payment_progress { :captured }
    charge_id { 'charge_id' }
  end
end

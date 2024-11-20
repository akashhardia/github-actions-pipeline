# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
#
#  id                   :bigint           not null, primary key
#  campaign_discount    :integer          default(0), not null
#  coupon_discount      :integer          default(0), not null
#  option_discount      :integer          default(0), not null
#  order_at             :datetime         not null
#  order_type           :integer          not null
#  refund_error_message :string(255)
#  returned_at          :datetime
#  total_price          :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  seat_sale_id         :bigint
#  user_coupon_id       :bigint
#  user_id              :bigint           not null
#
# Indexes
#
#  index_orders_on_seat_sale_id    (seat_sale_id)
#  index_orders_on_user_coupon_id  (user_coupon_id)
#  index_orders_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (seat_sale_id => seat_sales.id)
#  fk_rails_...  (user_coupon_id => user_coupons.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :order do
    user
    seat_sale
    order_at { '2020-10-07' }
    order_type { 0 }
    total_price { 10_000 }
    returned_at { nil }

    trait :with_ticket_reserve_in_admission do
      order_type { 1 }
      after(:create) do |order|
        ticket = create(:ticket, :ticket_with_admission_term, user: order.user, status: :sold, qr_ticket_id: AdmissionUuid.generate_uuid)
        option = create(:seat_type_option, seat_type: ticket.seat_type)
        order.total_price = ticket.price + option.price
        create(:ticket_reserve, :no_transfer, order: order, ticket: ticket, seat_type_option_id: option.id)
      end
    end

    trait :within_admission_and_logs do
      order_type { 1 }
      after(:create) do |order|
        ticket = create(:ticket, :ticket_with_admission_term, :with_ticket_logs, user: order.user, status: :sold, qr_ticket_id: AdmissionUuid.generate_uuid)
        option = create(:seat_type_option, seat_type: ticket.seat_type)
        order.total_price = ticket.price + option.price
        create(:ticket_reserve, :no_transfer, order: order, ticket: ticket, seat_type_option_id: option.id)
      end
    end

    trait :with_ticket_and_build_reserves do
      after(:build) do |o, _ev|
        ticket = create(:ticket, user: o.user)
        o.total_price = ticket.price
        o.ticket_reserves << build(:ticket_reserve, ticket: ticket, order: o)
      end
    end

    trait :with_ticket_and_build_reserves_sold do
      after(:build) do |o, _ev|
        ticket = create(:ticket, user: o.user, status: :sold)
        o.total_price = ticket.price
        o.ticket_reserves << build(:ticket_reserve, ticket: ticket, order: o)
      end
    end

    trait :payment_captured do
      after(:build) do |o, _ev|
        create(:payment, order: o, payment_progress: :captured)
      end
    end

    trait :payment_refunded do
      after(:build) do |o, _ev|
        create(:payment, order: o, payment_progress: :refunded)
      end
    end

    trait :payment_waiting_capture do
      after(:build) do |o, _ev|
        create(:payment, order: o, payment_progress: :waiting_capture)
      end
    end
  end
end

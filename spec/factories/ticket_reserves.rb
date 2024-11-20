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
FactoryBot.define do
  factory :ticket_reserve do
    order
    ticket
    seat_type_option
    transfer_at { nil }
    transfer_to_user_id { nil }
    transfer_from_user_id { nil }

    trait :no_transfer do
      transfer_at { nil }
      transfer_to_user_id { nil }
      transfer_from_user_id { nil }
    end
  end
end

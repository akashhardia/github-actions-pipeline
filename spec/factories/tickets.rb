# frozen_string_literal: true

# == Schema Information
#
# Table name: tickets
#
#  id                         :bigint           not null, primary key
#  admission_disabled_at      :datetime
#  row                        :string(255)
#  sales_type                 :integer          default("single"), not null
#  seat_number                :integer          not null
#  status                     :integer          default("available"), not null
#  transfer_uuid              :string(255)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  current_ticket_reserve_id  :bigint
#  master_seat_unit_id        :bigint
#  purchase_ticket_reserve_id :bigint
#  qr_ticket_id               :string(255)
#  seat_area_id               :bigint           not null
#  seat_type_id               :bigint           not null
#  user_id                    :bigint
#
# Indexes
#
#  fk_rails_a75cd836ef                   (purchase_ticket_reserve_id)
#  fk_rails_aa4180ad50                   (current_ticket_reserve_id)
#  index_tickets_on_master_seat_unit_id  (master_seat_unit_id)
#  index_tickets_on_seat_area_id         (seat_area_id)
#  index_tickets_on_seat_type_id         (seat_type_id)
#  index_tickets_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (current_ticket_reserve_id => ticket_reserves.id)
#  fk_rails_...  (master_seat_unit_id => master_seat_units.id)
#  fk_rails_...  (purchase_ticket_reserve_id => ticket_reserves.id)
#  fk_rails_...  (seat_area_id => seat_areas.id)
#  fk_rails_...  (seat_type_id => seat_types.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :ticket do
    seat_area
    seat_type
    status { :available }
    sales_type { :single }
    row { 'MyString' }
    seat_number { 'MyString' }
    master_seat_unit { nil }
    qr_ticket_id { nil }

    trait :sold do
      status { :sold }
    end

    trait :not_for_sale do
      status { :not_for_sale }
    end

    trait :temporary_hold do
      status { :temporary_hold }
    end

    trait :ticket_with_ticket_log do
      after(:create) do |ticket|
        create(:ticket_log, ticket: ticket)
      end
    end

    trait :with_ticket_logs do
      after(:create) do |ticket|
        create_list(:ticket_log, 2, ticket: ticket)
      end
    end

    trait :ticket_with_admission_term do
      seat_type { create(:seat_type, :seat_type_with_admission_term) }
    end

    trait :after_event do
      seat_type { create(:seat_type, :after_event) }
    end

    trait :today_event do
      seat_type { create(:seat_type, :today_event) }
    end

    trait :before_event_one_day do
      seat_type { create(:seat_type, :before_event_one_day) }
    end

    trait :before_event_over_one_day do
      seat_type { create(:seat_type, :before_event_over_one_day) }
    end

    after(:build) do |ticket|
      # seat_typeとseat_areaのseat_saleは同じものになる、seat_typeに合わせる
      ticket.seat_area.update(seat_sale: ticket.seat_type.seat_sale)
    end
  end
end

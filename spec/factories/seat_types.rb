# frozen_string_literal: true

# == Schema Information
#
# Table name: seat_types
#
#  id                    :bigint           not null, primary key
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  master_seat_type_id   :bigint           not null
#  seat_sale_id          :bigint           not null
#  template_seat_type_id :bigint           not null
#
# Indexes
#
#  index_seat_types_on_master_seat_type_id    (master_seat_type_id)
#  index_seat_types_on_seat_sale_id           (seat_sale_id)
#  index_seat_types_on_template_seat_type_id  (template_seat_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (master_seat_type_id => master_seat_types.id)
#  fk_rails_...  (seat_sale_id => seat_sales.id)
#  fk_rails_...  (template_seat_type_id => template_seat_types.id)
#
FactoryBot.define do
  factory :seat_type do
    seat_sale
    master_seat_type
    template_seat_type

    trait :available_for_sale do
      seat_sale { create(:seat_sale, :available) }
    end

    trait :seat_type_with_admission_term do
      seat_sale { create(:seat_sale, :in_admission_term) }
    end

    trait :after_event do
      seat_sale { create(:seat_sale, :after_event) }
    end

    trait :today_event do
      seat_sale { create(:seat_sale, :today_event) }
    end

    trait :before_event_one_day do
      seat_sale { create(:seat_sale, :before_event_one_day) }
    end

    trait :before_event_over_one_day do
      seat_sale { create(:seat_sale, :before_event_over_one_day) }
    end
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: template_seat_types
#
#  id                    :bigint           not null, primary key
#  price                 :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  master_seat_type_id   :bigint           not null
#  template_seat_sale_id :bigint           not null
#
# Indexes
#
#  index_template_seat_types_on_master_seat_type_id    (master_seat_type_id)
#  index_template_seat_types_on_template_seat_sale_id  (template_seat_sale_id)
#
# Foreign Keys
#
#  fk_rails_...  (master_seat_type_id => master_seat_types.id)
#  fk_rails_...  (template_seat_sale_id => template_seat_sales.id)
#
FactoryBot.define do
  factory :template_seat_type do
    master_seat_type
    template_seat_sale
    price { 1000 }

    trait :with_template_seat_type_options do
      after(:create) do |template_seat_type|
        create_list(:template_seat_type_option, 3, template_seat_type_id: template_seat_type.id)
      end
    end
  end
end

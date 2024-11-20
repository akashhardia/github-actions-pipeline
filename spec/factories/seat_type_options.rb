# frozen_string_literal: true

# == Schema Information
#
# Table name: seat_type_options
#
#  id                           :bigint           not null, primary key
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  seat_type_id                 :bigint           not null
#  template_seat_type_option_id :bigint           not null
#
# Indexes
#
#  index_seat_type_options_on_seat_type_id                  (seat_type_id)
#  index_seat_type_options_on_template_seat_type_option_id  (template_seat_type_option_id)
#
# Foreign Keys
#
#  fk_rails_...  (seat_type_id => seat_types.id)
#  fk_rails_...  (template_seat_type_option_id => template_seat_type_options.id)
#
FactoryBot.define do
  factory :seat_type_option do
    seat_type
    template_seat_type_option
  end
end

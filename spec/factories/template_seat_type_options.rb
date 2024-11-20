# frozen_string_literal: true

# == Schema Information
#
# Table name: template_seat_type_options
#
#  id                    :bigint           not null, primary key
#  companion             :boolean          default(FALSE), not null
#  description           :string(255)
#  price                 :integer          not null
#  title                 :string(255)      not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  template_seat_type_id :bigint           not null
#
# Indexes
#
#  index_template_seat_type_options_on_template_seat_type_id  (template_seat_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (template_seat_type_id => template_seat_types.id)
#
FactoryBot.define do
  sequence :template_seat_type_option_title do |i|
    "オプションタイトル #{i}"
  end

  factory :template_seat_type_option do
    title { generate :template_seat_type_option_title }
    price { 1 }
    template_seat_type
    companion { false }
  end
end

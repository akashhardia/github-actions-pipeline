# frozen_string_literal: true

# == Schema Information
#
# Table name: template_seat_sales
#
#  id          :bigint           not null, primary key
#  description :string(255)
#  immutable   :boolean          default(FALSE), not null
#  status      :integer          default("available"), not null
#  title       :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :template_seat_sale do
    title { 'MyString' }
    description { 'MyString' }
    status { :available }
    immutable { false }
  end
end

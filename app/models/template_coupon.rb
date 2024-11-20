# frozen_string_literal: true

# == Schema Information
#
# Table name: template_coupons
#
#  id         :bigint           not null, primary key
#  note       :text(65535)
#  rate       :integer          not null
#  title      :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class TemplateCoupon < ApplicationRecord
  has_many :coupons, dependent: :destroy

  validates :title, presence: true
  validates :rate, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end

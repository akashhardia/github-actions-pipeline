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
class TemplateSeatSale < ApplicationRecord
  has_many :template_seat_areas, dependent: :destroy
  has_many :template_seats, through: :template_seat_areas
  has_many :template_seat_types, dependent: :destroy
  has_many :template_seat_type_options, through: :template_seat_types
  has_many :seat_sales, dependent: :nullify
  has_many :template_seat_sale_schedules, dependent: :nullify

  # テンプレートの削除はせずにunavailable
  enum status: {
    available: 0, # 有効
    unavailable: 1 # 無効
  }

  # Validations -----------------------------------------------------------------------------------
  validates :immutable, inclusion: { in: [true, false] }
  validates :status, presence: true
  validates :title, presence: true

  # 販売実績の無いテンプレート(変更・削除可能)
  scope :mutable_templates, -> {
    ids = each_with_object([]) do |template_seat_sale, result|
      result << template_seat_sale.id unless template_seat_sale.template_immutable?
    end
    where(id: ids)
  }

  # 販売中のテンプレート(変更・削除不可)
  scope :already_on_sale, -> {
    ids = each_with_object([]) do |template_seat_sale, result|
      result << template_seat_sale.id if template_seat_sale.template_already_on_sale?
    end
    where(id: ids)
  }

  def template_immutable?
    # 販売実績のあるテンプレートは変更・削除不可
    immutable? || seat_sales.any?(&:accounting_target?) || template_seat_sale_schedules.present?
  end

  def template_already_on_sale?
    seat_sales.any?(&:already_on_sale?) || template_seat_sale_schedules.present?
  end
end

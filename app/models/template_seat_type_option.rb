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
class TemplateSeatTypeOption < ApplicationRecord
  belongs_to :template_seat_type

  delegate :template_seat_sale, to: :template_seat_type

  # Validations -----------------------------------------------------------------------------------
  validates :title, presence: true
  validates :template_seat_type_id, presence: true
  validates :price, numericality: { only_integer: true }, presence: true
  validate :valid_price

  private

  def valid_price
    return true if price.nil?
    return true if template_seat_type.nil?

    template_seats = template_seat_type.template_seats.includes(:master_seat)
    template_seat_type_price = template_seat_type.price
    if template_seats.any? { |ts| ts.master_seat.master_seat_unit_id.present? }
      max_unit_size = template_seats.group_by(&:master_seat_unit_id).values.map(&:size).max
      errors.add(:price, I18n.t('activerecord.errors.models.template_seat_type_option.minimum_price_is_below_zero')) if (price * max_unit_size + template_seat_type_price).negative?
    elsif (price + template_seat_type_price).negative?
      errors.add(:price, I18n.t('activerecord.errors.models.template_seat_type_option.minimum_price_is_below_zero'))
    end
  end
end

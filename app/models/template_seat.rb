# frozen_string_literal: true

# == Schema Information
#
# Table name: template_seats
#
#  id                    :bigint           not null, primary key
#  status                :integer          default("available"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  master_seat_id        :bigint           not null
#  template_seat_area_id :bigint           not null
#  template_seat_type_id :bigint           not null
#
# Indexes
#
#  index_template_seats_on_master_seat_id         (master_seat_id)
#  index_template_seats_on_template_seat_area_id  (template_seat_area_id)
#  index_template_seats_on_template_seat_type_id  (template_seat_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (master_seat_id => master_seats.id)
#  fk_rails_...  (template_seat_area_id => template_seat_areas.id)
#  fk_rails_...  (template_seat_type_id => template_seat_types.id)
#
class TemplateSeat < ApplicationRecord
  belongs_to :master_seat
  belongs_to :template_seat_area
  belongs_to :template_seat_type

  delegate :row, :seat_number, :sales_type, :single?, :unit?, :master_seat_unit_id, to: :master_seat
  delegate :name, to: :template_seat_type

  enum status: {
    available: 0, # 空席・購入可能
    not_for_sale: 1 # 販売停止
  }

  # Validations -----------------------------------------------------------------------------------
  validates :master_seat_id, presence: true
  validates :status, presence: true
  validates :template_seat_area_id, presence: true
  validates :template_seat_type_id, presence: true

  delegate :template_immutable?, to: :template_seat_type

  def stop_selling!
    raise ApiBadRequestError, I18n.t('custom_errors.template.template_is_immutable') if template_immutable?

    not_for_sale!
  end

  def release_from_stop_selling!
    raise ApiBadRequestError, I18n.t('custom_errors.template.template_is_immutable') if template_immutable?

    available!
  end
end

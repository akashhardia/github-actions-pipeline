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
class TemplateSeatType < ApplicationRecord
  belongs_to :master_seat_type
  belongs_to :template_seat_sale
  has_many :template_seats, dependent: :destroy
  has_many :template_seat_type_options, dependent: :destroy

  # Validations -----------------------------------------------------------------------------------
  validates :master_seat_type_id, presence: true
  validates :template_seat_sale_id, presence: true
  validates :price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, presence: true

  delegate :name, to: :master_seat_type
  delegate :template_immutable?, to: :template_seat_sale
end

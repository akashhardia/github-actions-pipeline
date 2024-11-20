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
class SeatTypeOption < ApplicationRecord
  belongs_to :seat_type
  belongs_to :template_seat_type_option
  has_many :ticket_reserves, dependent: :nullify

  # Validations -----------------------------------------------------------------------------------
  validates :seat_type_id, presence: true
  validates :template_seat_type_option_id, presence: true

  delegate :price, :title, :description, to: :template_seat_type_option
end

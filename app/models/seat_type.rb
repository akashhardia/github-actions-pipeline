# frozen_string_literal: true

# == Schema Information
#
# Table name: seat_types
#
#  id                    :bigint           not null, primary key
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  master_seat_type_id   :bigint           not null
#  seat_sale_id          :bigint           not null
#  template_seat_type_id :bigint           not null
#
# Indexes
#
#  index_seat_types_on_master_seat_type_id    (master_seat_type_id)
#  index_seat_types_on_seat_sale_id           (seat_sale_id)
#  index_seat_types_on_template_seat_type_id  (template_seat_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (master_seat_type_id => master_seat_types.id)
#  fk_rails_...  (seat_sale_id => seat_sales.id)
#  fk_rails_...  (template_seat_type_id => template_seat_types.id)
#
class SeatType < ApplicationRecord
  belongs_to :seat_sale
  has_many :tickets, dependent: :delete_all
  has_many :seat_type_options, dependent: :delete_all
  belongs_to :master_seat_type
  belongs_to :template_seat_type

  delegate :name, to: :master_seat_type
  delegate :price, to: :template_seat_type

  # Validations -----------------------------------------------------------------------------------
  validates :seat_sale_id, presence: true
  validates :master_seat_type_id, presence: true
  validates :template_seat_type_id, presence: true
end

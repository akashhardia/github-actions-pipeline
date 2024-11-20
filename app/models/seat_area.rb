# frozen_string_literal: true

# == Schema Information
#
# Table name: seat_areas
#
#  id                  :bigint           not null, primary key
#  displayable         :boolean          default(TRUE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  entrance_id         :bigint
#  master_seat_area_id :bigint           not null
#  seat_sale_id        :bigint           not null
#
# Indexes
#
#  index_seat_areas_on_entrance_id          (entrance_id)
#  index_seat_areas_on_master_seat_area_id  (master_seat_area_id)
#  index_seat_areas_on_seat_sale_id         (seat_sale_id)
#
# Foreign Keys
#
#  fk_rails_...  (entrance_id => entrances.id)
#  fk_rails_...  (master_seat_area_id => master_seat_areas.id)
#  fk_rails_...  (seat_sale_id => seat_sales.id)
#
class SeatArea < ApplicationRecord
  belongs_to :entrance, optional: true
  belongs_to :seat_sale
  has_many :tickets, dependent: :delete_all
  belongs_to :master_seat_area

  delegate :area_name, :area_code, :position, :sub_code, :sub_position, to: :master_seat_area

  # Validations -----------------------------------------------------------------------------------
  validates :seat_sale_id, presence: true
  validates :displayable, inclusion: { in: [true, false] }

  def track_name
    return nil if entrance.blank?

    entrance.track.name
  end

  def entrance_name
    entrance&.name
  end
end

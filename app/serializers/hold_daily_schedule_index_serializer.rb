# frozen_string_literal: true

# == Schema Information
#
# Table name: hold_daily_schedules
#
#  id            :bigint           not null, primary key
#  daily_no      :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  hold_daily_id :bigint           not null
#
# Indexes
#
#  index_hold_daily_schedules_on_hold_daily_id  (hold_daily_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_daily_id => hold_dailies.id)
#
class HoldDailyScheduleIndexSerializer < ApplicationSerializer
  attributes :id, :hold_daily_id, :daily_no

  has_many :seat_sales, serializer: SeatSaleIndexSerializer, if: :relation?
end

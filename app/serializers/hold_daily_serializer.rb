# frozen_string_literal: true

# == Schema Information
#
# Table name: hold_dailies
#
#  id            :bigint           not null, primary key
#  daily_branch  :integer          not null
#  daily_status  :integer          not null
#  event_date    :date             not null
#  hold_daily    :integer          not null
#  hold_id_daily :integer          not null
#  program_count :integer
#  race_count    :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  hold_id       :bigint           not null
#
# Indexes
#
#  index_hold_dailies_on_hold_id  (hold_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_id => holds.id)
#
class HoldDailySerializer < ActiveModel::Serializer
  attributes :id, :daily_branch, :daily_status, :event_date, :hold_daily,
             :hold_id_daily, :hold_id, :hold_name_jp, :track_code, :races

  def track_code
    object.hold.track_code
  end

  def hold_name_jp
    object.hold.hold_name_jp
  end

  def daily_status
    I18n.t("activerecord.attributes.hold_daily.daily_status.#{object.daily_status}")
  end

  def races
    return [] if object.races.blank?

    object.races.map do |race|
      {
        id: race.id,
        race_no: race.race_no,
        post_time: race.post_time,
        post_start_time: race.post_start_time,
        created_at: race.created_at,
        updated_at: race.updated_at
      }
    end
  end
end

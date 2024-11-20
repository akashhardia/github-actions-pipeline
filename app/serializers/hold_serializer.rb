# frozen_string_literal: true

# == Schema Information
#
# Table name: holds
#
#  id                 :bigint           not null, primary key
#  audience           :boolean
#  first_day          :date             not null
#  first_day_manually :date
#  girl               :boolean
#  grade_code         :string(255)      not null
#  hold_days          :integer          not null
#  hold_name_en       :string(255)
#  hold_name_jp       :string(255)
#  hold_status        :integer
#  period             :integer
#  promoter           :string(255)
#  promoter_code      :string(255)      not null
#  promoter_section   :integer
#  promoter_times     :integer
#  promoter_year      :integer
#  purpose_code       :string(255)      not null
#  repletion_code     :string(255)
#  round              :integer
#  season             :string(255)
#  time_zone          :integer
#  title_en           :string(255)
#  title_jp           :string(255)
#  track_code         :string(255)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  pf_hold_id         :string(255)      not null
#  tt_movie_yt_id     :string(255)
#
# Indexes
#
#  index_holds_on_hold_status  (hold_status)
#  index_holds_on_pf_hold_id   (pf_hold_id) UNIQUE
#
class HoldSerializer < ActiveModel::Serializer
  has_many :hold_dailies, if: -> { instance_options[:action] != :index }
  attributes :id, :first_day, :grade_code, :hold_days, :hold_name_en,
             :hold_name_jp, :hold_status, :promoter_code, :promoter_section,
             :promoter_times, :purpose_code, :repletion_code, :pf_hold_id, :track_code, :created_at, :updated_at
end

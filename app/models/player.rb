# frozen_string_literal: true

# == Schema Information
#
# Table name: players
#
#  id                :bigint           not null, primary key
#  area_code         :string(255)
#  birthday          :date
#  catchphrase       :string(255)
#  chest             :decimal(4, 1)
#  country_code      :string(255)
#  current_rank_code :string(255)
#  dash              :decimal(4, 2)
#  delete_day        :date
#  duration          :decimal(4, 2)
#  gender_code       :integer
#  graduate          :integer
#  height            :decimal(4, 1)
#  keirin_delete     :date
#  keirin_expiration :date
#  keirin_regist     :date
#  keirin_update     :date
#  lap_1000          :string(255)
#  lap_200           :string(255)
#  lap_400           :string(255)
#  leftgrip          :decimal(3, 1)
#  max_speed         :decimal(4, 2)
#  middle_delete     :date
#  middle_expiration :date
#  middle_regist     :date
#  middle_update     :date
#  name_en           :string(255)
#  name_jp           :string(255)
#  next_rank_code    :string(255)
#  player_class      :integer
#  regist_day        :date
#  regist_num        :integer
#  rightgrip         :decimal(3, 1)
#  spine             :decimal(5, 1)
#  thigh             :decimal(4, 1)
#  vital             :decimal(5, 1)
#  weight            :decimal(4, 1)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  pf_player_id      :string(255)
#
# Indexes
#
#  index_players_on_pf_player_id  (pf_player_id)
#
class Player < ApplicationRecord
  has_many :hold_players, dependent: :destroy
  has_many :holds, through: :hold_players
  has_many :mediated_players, through: :hold_players
  has_many :player_race_results, dependent: :destroy
  has_one :player_result, dependent: :destroy
  has_one :player_original_info, dependent: :destroy
  has_one :retired_player, dependent: :destroy
  scope   :offseted, ->(offset_count) do
    return if offset_count.blank?

    offset(offset_count)
  end
  scope :limited, ->(limit_count) do
    return if limit_count.blank?

    limit(limit_count)
  end

  scope :not_retired_players, -> do
    where.missing(:retired_player)
  end

  scope :active_pf_250_regist_id, ->(pf_250_regist_ids) do
    return not_retired_players if pf_250_regist_ids.blank?

    includes(:player_original_info).where(player_original_info: { pf_250_regist_id: pf_250_regist_ids })
  end
  scope   :sorted, ->(item) { order(item) }
  scope   :sorted_with_player_original_info, ->(item) { includes(:player_original_info).order(item.to_s) }
  scope   :reverse_sorted_with_player_original_info, ->(item) { includes(:player_original_info).order("#{item} DESC") }
  scope   :sorted_with_pf_250_regist_id, -> { includes(:player_original_info).order('char_length(pf_250_regist_id)', 'pf_250_regist_id') }

  # Validations -----------------------------------------------------------------------------------
  delegate :last_name_jp, :first_name_jp, :last_name_en, :first_name_en, :speed, :stamina, :power, :technique, :mental,
           :growth, :original_record, :popular, :experience, :evaluation, :nickname, :comment, :season_best, :year_best, :round_best,
           :race_type, :major_title, :pist6_title, :free1, :free2, :free3, :free4, :free5, :free6, :free7, :free8, to: :player_original_info, allow_nil: true
  delegate :winner_rate, :first_count, :first_place_count, :second_place_count, :second_quinella_rate, :third_quinella_rate, :entry_count,
           :run_count, :first_count, :second_count, :third_count, :outside_count, to: :player_result, allow_nil: true
  delegate :pf_250_regist_id, to: :player_original_info, allow_nil: true

  EVALUATION_RANGES = { C: 0..57, B: 58..69, A: 70..81, S: 82..89, SS: 90..100 }.freeze

  def evaluation_range(value)
    return nil if value.blank?

    EVALUATION_RANGES.find { |k, v| return k if v.cover?(value) == true }
  end

  def self.evaluation_select(evaluation)
    evl = ''
    Player::EVALUATION_RANGES.each do |key, value|
      evl = key if value.include?(evaluation)
    end
    evl
  end

  def self.find_active_pf_player_id(pf_player_id)
    return if pf_player_id.blank?

    find_by(pf_player_id: pf_player_id)
  end
end

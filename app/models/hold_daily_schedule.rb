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
class HoldDailySchedule < ApplicationRecord
  DAILY_NO = {
    am: 'デイ',
    pm: 'ナイト'
  }.freeze

  DAILY_OPENING_1 = {
    am: '11:00',
    pm: '16:30'
  }.freeze

  DAILY_OPENING_2 = {
    am: '10:30',
    pm: '16:00'
  }.freeze

  DAILY_OPENING_3 = {
    am: '13:30',
    pm: '17:50'
  }.freeze

  DAILY_OPENING_4 = {
    am: '12:00',
    pm: '16:20'
  }.freeze

  DAILY_START_1 = {
    am: '12:25',
    pm: '17:55'
  }.freeze

  DAILY_START_2 = {
    am: '',
    pm: ''
  }.freeze

  DAILY_START_3 = {
    am: '14:00',
    pm: '18:20'
  }.freeze

  DAILY_START_4 = {
    am: '13:00',
    pm: '17:20'
  }.freeze

  belongs_to :hold_daily
  has_many :seat_sales, dependent: :nullify
  has_many :races, dependent: :destroy
  has_many :coupon_hold_daily_conditions, dependent: :destroy
  has_many :campaign_hold_daily_schedules, dependent: :destroy
  has_many :campaigns, through: :campaign_hold_daily_schedules
  has_many :tickets, through: :seat_sales

  delegate :daily_branch, :daily_status, :event_date, :hold_id_daily, :program_count, :race_count, :hold_id, :hold_name_jp, :promoter_year, :period, :round, to: :hold_daily
  delegate :hold_daily, to: :hold_daily, prefix: :column
  delegate :hold, to: :hold_daily

  validates :daily_no, presence: true

  scope :filter_holds, -> do
    where.not(hold: { promoter_year: nil }).where.not(hold: { period: nil }).where.not(hold: { round: nil })
  end

  scope :filter_races, -> do
    where.not(races: { details_code: nil })
  end

  scope :sorted_with_event_date_daily_no, -> { includes(:hold_daily).order('hold_dailies.event_date').order(:daily_no) }

  enum daily_no: {
    am: 0, # デイ
    pm: 1 # ナイト
  }

  # チケット販売可能かどうかのチェック
  # true->販売可能 false->不可能
  def available?
    !!available_seat_sale&.available?
  end

  # クーポン作成可能かどうかのチェック
  # true->作成可能 false->不可能
  def can_create_coupon?
    !!available_seat_sale&.can_create_coupon?
  end

  def available_seat_sale
    seat_sales.find { |seat_sale| !seat_sale.discontinued? }
  end

  def sales_status
    available_seat_sale&.sales_status || 'uncreated'
  end

  def before_and_being_held?
    hold_daily.before_held? || hold_daily.being_held?
  end

  def high_priority_event_code
    Constants::PRIORITIZED_EVENT_CODE_LIST.find { |code| event_code_list&.include?(code) } || event_code_list&.first
  end

  def day_night_display
    DAILY_NO[daily_no.to_sym]
  end

  def opening_display
    case hold.time_zone
    when 1
      DAILY_OPENING_1[daily_no.to_sym]
    when 2
      DAILY_OPENING_2[daily_no.to_sym]
    when 3
      DAILY_OPENING_3[daily_no.to_sym]
    when 4
      DAILY_OPENING_4[daily_no.to_sym]
    else
      DAILY_OPENING_1[daily_no.to_sym]
    end
  end

  def start_display
    case hold.time_zone
    when 1
      DAILY_START_1[daily_no.to_sym]
    when 2
      DAILY_START_2[daily_no.to_sym]
    when 3
      DAILY_START_3[daily_no.to_sym]
    when 4
      DAILY_START_4[daily_no.to_sym]
    else
      DAILY_START_1[daily_no.to_sym]
    end
  end

  private

  def event_code_list
    races.each_with_object([]) do |race, arr|
      next if race.event_code.blank?

      # event_code == "W", "X", "Y"（順位決定戦C,D,E）の場合はすべて"T"（順位決定戦）に変換
      if %w[W X Y].include? race.event_code
        arr << 'T'
        next
      end

      arr << race.event_code
    end
  end
end

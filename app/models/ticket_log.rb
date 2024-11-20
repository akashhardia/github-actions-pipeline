# frozen_string_literal: true

# == Schema Information
#
# Table name: ticket_logs
#
#  id               :bigint           not null, primary key
#  face_recognition :integer
#  failed_message   :integer
#  log_type         :integer          not null
#  request_status   :integer          not null
#  result           :integer          not null
#  result_status    :integer          not null
#  status           :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  device_id        :string(255)
#  ticket_id        :bigint
#
# Indexes
#
#  index_ticket_logs_on_ticket_id  (ticket_id)
#
# Foreign Keys
#
#  fk_rails_...  (ticket_id => tickets.id)
#
class TicketLog < ApplicationRecord
  belongs_to :ticket

  enum log_type: {
    action_log: 0, # 各ゲートで実施する通常のアクション
    clean_log: 1,  # チケットを削除したときのログ
    validate_log: 2 # バリデーションかけたときのログ
  }

  enum request_status: {
    before_enter: 0, # 入場前
    entered: 1, # 入場済
    temporary_left: 2, # 一時退場
    enter_again: 3, # 再入場
    left: 4, # 退場済
    expired: 5, # 有効期限切れ
    expelled: 6, # 追放
    invalid_value: 99 # 不正な値
  }, _prefix: true

  enum status: {
    before_enter: 0,
    entered: 1,
    temporary_left: 2,
    enter_again: 3,
    left: 4,
    expired: 5,
    expelled: 6
  }, _prefix: true

  enum result: {
    'false' => 0,
    'true' => 1
  }, _prefix: true

  enum face_recognition: {
    authentication_succeeded: 0,
    authentication_failed: 1,
    registration_completed: 2,
    shooting_failed: 3,
    failed: 4
  }

  enum result_status: {
    before_enter: 0,
    entered: 1,
    temporary_left: 2,
    enter_again: 3,
    left: 4,
    expired: 5,
    expelled: 6
  }, _prefix: true

  enum failed_message: {
    ticket_not_found: 0,
    ticket_has_expired: 1,
    ticket_not_available_yet: 2,
    ticket_validate_failed: 3,
    the_value_you_have_entered_is_invalid: 4,
    the_request_ticket_id_field_is_required: 5,
    the_request_request_status_field_is_required: 6,
    the_request_result_field_is_required: 7,
    ticket_cannot_clean: 8
  }

  # Validations -----------------------------------------------------------------------------------
  validates :log_type, presence: true
  validates :request_status, presence: true
  validates :result, presence: true
  validates :result_status, presence: true
  validates :status, presence: true
  validates :ticket_id, presence: true
end

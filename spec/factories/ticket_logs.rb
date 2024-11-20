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
FactoryBot.define do
  factory :ticket_log do
    association :ticket, factory: :ticket
    log_type { 0 }
    request_status { 0 }
    status { 1 }
    result { 0 }
    face_recognition { 0 }
    result_status { 0 }
    failed_message { 0 }
  end
end

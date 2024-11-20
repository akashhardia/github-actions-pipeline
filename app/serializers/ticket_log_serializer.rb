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
class TicketLogSerializer < ActiveModel::Serializer
  attributes :id, :ticket_id, :log_type, :request_status, :status, :result,
             :face_recognition, :result_status, :failed_message, :created_at, :updated_at, :device_id
end

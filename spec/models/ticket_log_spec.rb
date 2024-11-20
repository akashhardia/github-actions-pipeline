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
require 'rails_helper'

RSpec.describe TicketLog, type: :model do
  describe 'validationの確認' do
    let(:ticket) { create(:ticket) }

    it 'log_typeがなければerrorになること' do
      ticket_log = described_class.new(request_status: :before_enter, result: 'true', result_status: :before_enter, status: :before_enter, ticket: ticket)
      expect(ticket_log.valid?).to eq false
    end

    it 'request_statusがなければerrorになること' do
      ticket_log = described_class.new(log_type: :action_log, result: 'true', result_status: :before_enter, status: :before_enter, ticket: ticket)
      expect(ticket_log.valid?).to eq false
    end

    it 'resultがなければerrorになること' do
      ticket_log = described_class.new(log_type: :action_log, request_status: :before_enter, result_status: :before_enter, status: :before_enter, ticket: ticket)
      expect(ticket_log.valid?).to eq false
    end

    it 'result_statusがなければerrorになること' do
      ticket_log = described_class.new(log_type: :action_log, request_status: :before_enter, result: 'true', status: :before_enter, ticket: ticket)
      expect(ticket_log.valid?).to eq false
    end

    it 'statusがなければerrorになること' do
      ticket_log = described_class.new(log_type: :action_log, request_status: :before_enter, result: 'true', result_status: :before_enter, ticket: ticket)
      expect(ticket_log.valid?).to eq false
    end

    it 'ticket_idがなければerrorになること' do
      ticket_log = described_class.new(log_type: :action_log, request_status: :before_enter, result: 'true', result_status: :before_enter, status: :before_enter)
      expect(ticket_log.valid?).to eq false
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe 'face_recognition' do # rubocop:disable RSpec/DescribeClass
  describe 'delete_face_recognition(ticket_id)' do
    context '顔認証情報削除が成功する場合' do
      let(:ticket) { create(:ticket, qr_ticket_id: 1) }

      it 'status: :okが返ってくる' do
        response = FaceRecognition::ApiMock.delete_face_recognition(ticket.qr_ticket_id)
        expect(response).to be_ok
      end
    end

    context 'API認証が失敗する場合、status: :unauthorizeが返ってくる' do
      let(:ticket) { create(:ticket, qr_ticket_id: 2) }

      it 'NotAuthorizedエラーが返る' do
        response = FaceRecognition::ApiMock.delete_face_recognition(ticket.qr_ticket_id)
        expect(response).to be_unauthorized
      end
    end
  end

  context '対象のチケットの顔認証情報がない場合' do
    let(:ticket) { create(:ticket, qr_ticket_id: 9999) }

    it 'status: :not_foundが返ってくる' do
      response = FaceRecognition::ApiMock.delete_face_recognition(ticket.qr_ticket_id)
      expect(response).to be_not_found
    end
  end
end

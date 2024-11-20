# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SeatAreas', :admin_logged_in, type: :request do
  describe 'GET admin/seat_areas' do
    subject(:seat_area_index) { get admin_seat_areas_url(seat_sale_id: seat_sale.id) }

    let(:seat_area1) { create(:seat_area, seat_sale: seat_sale) }
    let(:seat_area2) { create(:seat_area, seat_sale: seat_sale) }
    let(:seat_sale) { create(:seat_sale) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }

    before do
      create_list(:ticket, 3, seat_area: seat_area1, seat_type: seat_type, status: 'available')
      create_list(:ticket, 3, seat_area: seat_area2, seat_type: seat_type)
    end

    context '存在する販売を取得したとき' do
      it '対応するエリアの一覧と販売のカウント情報が返ってくること' do
        seat_area_index
        expect(response).to have_http_status(:ok)

        data = JSON.parse(response.body)

        expect_keys = %w[id areaName areaCode displayable areaSalesType availableSeatsCount soldSeatsCount notForSaleSeatsCount availableUnitSeatsCount soldUnitSeatsCount notForSaleUnitSeatsCount]
        expect(expect_keys).to include_keys(data.first.keys)
        expect(data.first['availableSeatsCount']).to eq(3)
      end
    end
  end

  describe 'GET admin/seat_areas/:id' do
    subject(:seat_area_show) { get admin_seat_area_url(seat_area.id) }

    let(:seat_area) { create(:seat_area) }

    before do
      create_list(:ticket, 3, seat_area: seat_area)
    end

    context '存在するエリアを取得したとき' do
      it '選択したエリアのチケット情報が返ってくること' do
        seat_area_show
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json.size).to eq(3)

        expect_keys = %w[transferUuid qrTicketId userId unitType unitName]
        expect(expect_keys).to include_keys json.first.keys
      end
    end
  end
end

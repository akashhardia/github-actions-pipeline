# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TemplateSeatArea', :admin_logged_in, type: :request do
  describe 'GET admin/template_seat_areas' do
    subject(:template_seat_area_index) { get admin_template_seat_areas_url(template_seat_sale_id: template_seat_sale.id) }

    let(:template_seat_area1) { create(:template_seat_area, template_seat_sale: template_seat_sale) }
    let(:template_seat_area2) { create(:template_seat_area, template_seat_sale: template_seat_sale) }
    let(:template_seat_sale) { create(:template_seat_sale) }

    before do
      create_list(:template_seat, 3, template_seat_area: template_seat_area1, status: 'available')
      create_list(:template_seat, 3, template_seat_area: template_seat_area2)
    end

    context '存在する販売を取得したとき' do
      it '対応するエリアの一覧と販売のカウント情報が返ってくること' do
        template_seat_area_index
        expect(response).to have_http_status(:ok)

        data = JSON.parse(response.body)

        expect_keys = %w[id areaName areaCode position displayable areaSalesType availableSeatsCount notForSaleSeatsCount availableUnitSeatsCount notForSaleUnitSeatsCount]
        expect(expect_keys).to include_keys(data.first.keys)
        expect(data.first['availableSeatsCount']).to eq(3)
      end
    end
  end

  describe 'GET admin/template_seat_areas/:id' do
    subject(:template_seat_area_show) { get admin_template_seat_area_url(template_seat_area.id) }

    let(:template_seat_area) { create(:template_seat_area) }

    before do
      create_list(:template_seat, 3, template_seat_area: template_seat_area)
    end

    context '存在するエリアを取得したとき' do
      it '選択したエリアのチケット情報が返ってくること' do
        template_seat_area_show
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json.size).to eq(3)

        expect_keys = %w[id status row seatNumber salesType masterSeatUnitId unitType unitName]
        expect(expect_keys).to include_keys json.first.keys
      end
    end
  end
end

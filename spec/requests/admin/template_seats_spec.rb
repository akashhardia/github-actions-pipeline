# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TemplateSeats', :admin_logged_in, type: :request do
  describe 'PUT /template_seats/stop_selling' do
    subject(:template_seat_stop_selling) { put admin_template_seat_stop_selling_url, params: params }

    let(:template_seat1) { create(:template_seat, template_seat_type: template_seat_type) }
    let(:template_seat_type) { create(:template_seat_type, template_seat_sale: template_seat_sale) }
    let(:template_seat_sale) { create(:template_seat_sale) }

    let(:params) { { template_seat_ids: template_seat_ids } }
    let(:template_seat_ids) { [template_seat1.id] }

    it '変更したシート情報を返すこと' do
      template_seat_stop_selling
      data = JSON.parse(response.body)
      expect_data = %w[id status seatNumber salesType masterSeatUnitId unitType unitName]
      expect(expect_data).to include_keys(data.first.keys)
    end

    context 'シート一席を指定した場合' do
      it 'statusがnot_for_saleに更新されていること' do
        expect { template_seat_stop_selling }.to change { template_seat1.reload.status }.from('available').to('not_for_sale')
      end
    end

    context 'シート複数席を指定した場合' do
      let(:template_seat2) { create(:template_seat, template_seat_type: template_seat_type) }
      let(:template_seat3) { create(:template_seat, template_seat_type: template_seat_type) }

      let(:template_seat_ids) { [template_seat1.id, template_seat2.id, template_seat3.id] }

      it 'statusが全てnot_for_saleに更新されていること' do
        expect { template_seat_stop_selling }.to change {
          [template_seat1, template_seat2, template_seat3].all? { |template_seat| template_seat.reload.status == 'not_for_sale' }
        }.from(false).to(true)
      end
    end

    context 'テンプレートが変更不可な場合' do
      let(:template_seat_sale) { create(:template_seat_sale, immutable: true) }

      it 'statusが更新されないこと' do
        expect { template_seat_stop_selling }.not_to change { template_seat1.reload.status }
      end
    end

    context '存在しないtemplate_seat_idsが含まれている場合' do
      let(:template_seat_ids) { [1] }

      it 'エラーが発生すること' do
        template_seat_stop_selling
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:not_found)
        expect(body['detail']).to eq('存在しないチケットが含まれています')
      end
    end
  end

  describe 'PUT /template_seats/release_from_stop_selling' do
    subject(:template_seat_release_from_stop_selling) { put admin_template_seat_release_from_stop_selling_url, params: params }

    let(:template_seat1) { create(:template_seat, template_seat_type: template_seat_type) }
    let(:template_seat_type) { create(:template_seat_type, template_seat_sale: template_seat_sale) }
    let(:template_seat_sale) { create(:template_seat_sale) }

    let(:params) { { template_seat_ids: template_seat_ids } }
    let(:template_seat_ids) { [template_seat1.id] }

    context 'シート一席を指定した場合' do
      before do
        put admin_template_seat_stop_selling_url, params: params
      end

      it '変更したシート情報を返すこと' do
        template_seat_release_from_stop_selling
        data = JSON.parse(response.body)
        expect_data = %w[id status seatNumber salesType masterSeatUnitId unitType unitName]
        expect(expect_data).to include_keys(data.first.keys)
      end

      it 'statusがavailableに更新されていること' do
        expect { template_seat_release_from_stop_selling }.to change { template_seat1.reload.status }.from('not_for_sale').to('available')
      end
    end

    context 'シート複数席を指定した場合' do
      before do
        put admin_template_seat_stop_selling_url, params: params
      end

      let(:template_seat2) { create(:template_seat, template_seat_type: template_seat_type) }
      let(:template_seat3) { create(:template_seat, template_seat_type: template_seat_type) }

      let(:template_seat_ids) { [template_seat1.id, template_seat2.id, template_seat3.id] }

      it 'statusが全てnot_for_saleに更新されていること' do
        expect { template_seat_release_from_stop_selling }.to change {
          [template_seat1, template_seat2, template_seat3].all? { |template_seat| template_seat.reload.status == 'available' }
        }.from(false).to(true)
      end
    end

    context 'テンプレートが変更不可の場合' do
      before do
        put admin_template_seat_stop_selling_url, params: params
      end

      let(:template_seat_sale) { create(:template_seat_sale, immutable: true) }

      it 'statusが更新されないこと' do
        expect { template_seat_release_from_stop_selling }.not_to change { template_seat1.reload.status }
      end
    end

    context '存在しないtemplate_seat_idsが含まれている場合' do
      let(:template_seat_ids) { [1] }

      it 'エラーが発生すること' do
        template_seat_release_from_stop_selling
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:not_found)
        expect(body['detail']).to eq('存在しないチケットが含まれています')
      end
    end
  end
end

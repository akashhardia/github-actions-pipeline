# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TemplateSeatSaleSchedules', :admin_logged_in, type: :request do
  describe 'GET /template_seat_sale_schedules' do
    subject(:template_seat_sale_schedule_index) { get admin_template_seat_sale_schedules_url(format: :json) }

    before do
      create_list(:template_seat_sale_schedule, 4)
      create_list(:template_seat_sale, 3)
    end

    it 'HTTPステータスが200であること' do
      template_seat_sale_schedule_index
      expect(response).to have_http_status(:ok)
    end

    it 'jsonは::TemplateSeatSaleScheduleの属性を持つハッシュであること' do
      template_seat_sale_schedule_index
      json = JSON.parse(response.body)['templateSeatSaleSchedules']
      expect(json.size).to eq(4)
      json.all? { |hash| expect(hash.keys).to match_array(::TemplateSeatSaleScheduleSerializer._attributes.map { |key| key.to_s.camelize(:lower) }) }
      json = JSON.parse(response.body)['templateSeatSales']
      expect(json.size).to eq(7)
      json.all? { |hash| expect(hash.keys).to match_array(%w[description id immutable status title].map { |key| key.to_s.camelize(:lower) }) }
    end
  end

  describe 'PUT /template_seat_sale_schedules' do
    subject(:template_seat_sale_schedule_update) { put admin_template_seat_sale_schedules_url, params: params }

    let(:template_seat_sale_schedule_1) { create(:template_seat_sale_schedule, target_hold_schedule: 0) }
    let(:template_seat_sale_schedule_2) { create(:template_seat_sale_schedule, target_hold_schedule: 1) }
    let(:template_seat_sale) { create(:template_seat_sale) }

    let(:params) do
      {
        template_seat_sale_schedules: [
          {
            id: template_seat_sale_schedule_1.id,
            admission_available_time: template_seat_sale_schedule_1.admission_available_time,
            admission_close_time: template_seat_sale_schedule_1.admission_close_time,
            sales_end_time: '13:00',
            template_seat_sale_id: template_seat_sale_schedule_1.template_seat_sale_id
          },
          {
            id: template_seat_sale_schedule_2.id,
            admission_available_time: template_seat_sale_schedule_2.admission_available_time,
            admission_close_time: template_seat_sale_schedule_2.admission_close_time,
            sales_end_time: template_seat_sale_schedule_2.sales_end_time,
            template_seat_sale_id: template_seat_sale.id
          }
        ]
      }
    end

    it '対象のtemplate_seat_sale_scheduleが更新されること' do
      old_sales_end_time = template_seat_sale_schedule_1.sales_end_time
      old_template_seat_sale_id = template_seat_sale_schedule_2.template_seat_sale_id
      expect { template_seat_sale_schedule_update }.to \
        change { template_seat_sale_schedule_1.reload.sales_end_time }.from(old_sales_end_time).to('13:00').and \
          change { template_seat_sale_schedule_2.reload.template_seat_sale_id }.from(old_template_seat_sale_id).to(template_seat_sale.id)
    end

    context 'パラメータが不足している場合' do
      let(:params) do
        {
          template_seat_sale_schedules: [
            {
              id: template_seat_sale_schedule_1.id,
              admission_available_time: template_seat_sale_schedule_1.admission_available_time,
              admission_close_time: template_seat_sale_schedule_1.admission_close_time,
              sales_end_time: nil,
              template_seat_sale_id: template_seat_sale_schedule_1
            }
          ]
        }
      end

      it '400エラーが返ること' do
        template_seat_sale_schedule_update
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end

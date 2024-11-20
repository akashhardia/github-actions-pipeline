# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AnnualSchedulesController', :admin_logged_in, type: :request do
  describe 'GET /admin/annual_schedules' do
    context 'クエリパラメータが無い場合' do
      subject(:annual_schedules_index) { get admin_annual_schedules_url(format: :json) }

      before do
        create(:annual_schedule)
      end

      it 'HTTPステータスが200であること' do
        annual_schedules_index
        expect(response).to have_http_status(:ok)
      end

      it 'jsonはAdmin::AnnualScheduleSerializerの属性を持つハッシュであること' do
        annual_schedules_index
        json = JSON.parse(response.body)
        arr = %w[id track_code first_day active created_at updated_at].map { |key| key.to_s.camelize(:lower) }
        json.all? { |hash| expect(hash.keys).to match_array(arr) }
      end
    end

    context 'クエリパラメータが有る場合' do
      subject(:annual_schedules_index) { get admin_annual_schedules_url + '?date=2021-09-01' }

      let!(:annual_schedule) { create(:annual_schedule, first_day: '2021-09-02') }

      before do
        create_list(:annual_schedule, 2)
      end

      it 'クエリパラメータで指定されている日付以降の予定開催日(初日)が設定されている開催のみ取得できる' do
        annual_schedules_index
        json = JSON.parse(response.body)
        expect(json.size).to eq(1)
        expect(json[0]['id']).to eq(annual_schedule.id)
      end
    end
  end

  describe 'PUT /admin/annual_schedules/:id/change_activation' do
    subject(:change_activation) { put change_activation_admin_annual_schedule_url(annual_schedule), params: params }

    let(:annual_schedule) { create(:annual_schedule, active: active_column) }

    context 'パラメータが無い場合' do
      let(:params) { { active: nil } }
      let(:active_column) { false }

      it 'HTTPステータスが400であること' do
        change_activation
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'パラメータがactive: trueの場合' do
      let(:params) { { active: true } }
      let(:active_column) { false }

      it 'activeの値をtrueに変更する' do
        expect { change_activation }.to change { annual_schedule.reload.active }.from(false).to(true)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'パラメータがactive: falseの場合' do
      let(:params) { { active: false } }
      let(:active_column) { true }

      it 'activeの値をfalseに変更する' do
        expect { change_activation }.to change { annual_schedule.reload.active }.from(true).to(false)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end

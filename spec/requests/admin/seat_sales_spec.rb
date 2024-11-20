# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SeatSalesController', :admin_logged_in, type: :request do
  describe 'discontinue PUT /admin/seat_sales/discontinue' do
    subject(:seat_sale_discontinue) { put admin_discontinue_url(id: seat_sale.id) }

    let(:seat_sale) { create(:seat_sale, :available, sales_status: sales_status) }

    context '販売中である場合' do
      let(:sales_status) { :on_sale }

      it '販売中止ステータスに変更されること' do
        expect { seat_sale_discontinue }.to change { seat_sale.reload.sales_status }.from('on_sale').to('discontinued')
      end
    end

    context '販売前である場合' do
      let(:sales_status) { :before_sale }

      it '販売中止ステータスに変更されないこと' do
        expect { seat_sale_discontinue }.not_to change { seat_sale.reload.sales_status }
      end
    end
  end

  describe 'update PUT seat_sales/:id/update' do
    subject(:seat_sale_update) { put "/admin/seat_sales/#{seat_sale.id}/update", params: params }

    let(:seat_sale) { create(:seat_sale, :not_selling) }
    let(:request_start_time) { Time.zone.now + 3.hours }
    let(:params) { { sales_start_at: request_start_time, sales_end_at: request_start_time + 12.hours, admission_available_at: request_start_time, admission_close_at: request_start_time + 12.hours } }

    it 'HTTPステータスが200であること' do
      seat_sale_update
      expect(response).to have_http_status(:ok)
    end

    context '販売開始時間がまだな場合' do
      it '時間が更新されていること' do
        original_start_at = seat_sale.sales_start_at
        original_end_at = seat_sale.sales_end_at
        expect { seat_sale_update }.to change { SeatSale.find(seat_sale.id).sales_start_at.hour }.from(original_start_at.hour).to(params[:sales_start_at].hour).and \
          change { SeatSale.find(seat_sale.id).sales_end_at.hour }.from(original_end_at.hour).to(params[:sales_end_at].hour)
      end

      context 'nilのparamsの場合' do
        let(:params) { { sales_start_at: nil, sales_end_at: nil } }

        it '時間が更新されないこと' do
          original_start_at = seat_sale.sales_start_at
          original_end_at = seat_sale.sales_end_at
          seat_sale_update
          seat_sale.reload
          expect(seat_sale.sales_start_at.hour).to eq original_start_at.hour
          expect(seat_sale.sales_end_at.hour).to eq original_end_at.hour
          json = JSON.parse(response.body)
          expect(json['status']).to eq 400
        end
      end

      context '販売開始時間が販売終了時間を超えていた場合' do
        let(:seat_sale) { create(:seat_sale, :not_selling) }

        let(:params) { { sales_start_at: Time.zone.now + 7.hours, sales_end_at: Time.zone.now + 6.hours } }

        it '時間が更新されないこと' do
          original_start_at = seat_sale.sales_start_at
          original_end_at = seat_sale.sales_end_at
          seat_sale_update
          seat_sale.reload
          expect(seat_sale.sales_start_at.hour).to eq original_start_at.hour
          expect(seat_sale.sales_end_at.hour).to eq original_end_at.hour
          json = JSON.parse(response.body)
          expect(json['status']).to eq 400
        end
      end
    end

    context '入場時間テスト' do
      let(:seat_sale) { create(:seat_sale, :before_admission_close_time) }

      context '入場終了時間がまだな場合' do
        it '時間が更新されていること' do
          original_admission_available_at = seat_sale.admission_available_at
          original_admission_close_at = seat_sale.admission_close_at
          expect { seat_sale_update }.to change { SeatSale.find(seat_sale.id).admission_available_at.hour }.from(original_admission_available_at.hour).to(params[:admission_available_at].hour).and \
            change { SeatSale.find(seat_sale.id).admission_close_at.hour }.from(original_admission_close_at.hour).to(params[:admission_close_at].hour)
        end
      end
    end
  end

  describe 'duplicate POST seat_sales/:id/duplicate' do
    subject(:seat_sale_duplicate) { post admin_duplicate_seat_sale_url(seat_sale_id) }

    let(:hold_daily_schedule) { create(:hold_daily_schedule) }
    let(:seat_sale_id) { SeatSale.find_by(hold_daily_schedule_id: hold_daily_schedule.id).id }
    let(:template_seat_sale) { create(:template_seat_sale) }

    before do
      template_seat_area = create(:template_seat_area, template_seat_sale: template_seat_sale)
      template_seat_type = create(:template_seat_type, template_seat_sale: template_seat_sale)

      10.times do |i|
        create(:master_seat, master_seat_area: template_seat_area.master_seat_area, master_seat_type: template_seat_type.master_seat_type, row: i + 1)
        create(:template_seat, template_seat_area: template_seat_area, template_seat_type: template_seat_type)
        create(:template_seat_type_option, template_seat_type: template_seat_type)
      end

      tickets_params = {
        hold_daily_schedule_id: hold_daily_schedule.id,
        template_seat_sale_id: template_seat_sale.id,
        sales_start_at: Time.zone.now,
        sales_end_at: Time.zone.now + 5.days,
        admission_available_at: Time.zone.now + 6.days,
        admission_close_at: Time.zone.now + 7.days
      }

      # コピーのための販売情報の作成
      TicketsCreator.new(tickets_params).create_all_tickets!
    end

    context 'seat_saleステータスがdiscontinuedの場合' do
      it 'HTTPステータスが200であること' do
        SeatSale.find(seat_sale_id).discontinued!
        seat_sale_duplicate
        expect(response).to have_http_status(:ok)
      end

      it 'コピーされたseat_saleの各項目が正しくコピーされていること、sales_statuはbefore_statusであること' do
        original = SeatSale.find(seat_sale_id)
        original.discontinued!
        seat_sale_duplicate
        copy = hold_daily_schedule.seat_sales.where.not(id: original.id).first
        expect(original.template_seat_sale_id).to eq(copy.template_seat_sale_id)
        expect(original.hold_daily_schedule_id).to eq(copy.hold_daily_schedule_id)
        expect(original.sales_start_at).to eq(copy.sales_start_at)
        expect(original.sales_end_at).to eq(copy.sales_end_at)
        expect(original.admission_available_at).to eq(copy.admission_available_at)
        expect(original.admission_close_at).to eq(copy.admission_close_at)
        expect(copy).to be_before_sale
      end
    end

    context 'seat_saleが存在しない場合404が返ってくること' do
      let(:seat_sale_id) { 9999 }

      it 'HTTPステータスが404であること' do
        seat_sale_duplicate
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'seat_saleのステータスがdiscontinuedでない場合422が返ってくること' do
      it 'HTTPステータスが422であること' do
        seat_sale_duplicate
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'seat_saleのステータスがdiscontinuedでも、hold_daily_scheduleに有効な販売情報があった場合422が返ってくること' do
      it 'HTTPステータスが422であること' do
        SeatSale.find(seat_sale_id).discontinued!
        tickets_params = {
          hold_daily_schedule_id: hold_daily_schedule.id,
          template_seat_sale_id: template_seat_sale.id,
          sales_start_at: Time.zone.now,
          sales_end_at: Time.zone.now + 5.days,
          admission_available_at: Time.zone.now + 6.days,
          admission_close_at: Time.zone.now + 7.days
        }

        # 販売情報の作成
        TicketsCreator.new(tickets_params).create_all_tickets!

        seat_sale_duplicate
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'index GET /admin/seat_sales' do
    subject(:seat_sale_index) { get admin_hold_dailies_seat_sales_url(format: :json, event_date: hold_daily.event_date) }

    let(:hold_daily_schedule) { create(:hold_daily_schedule, hold_daily_id: hold_daily.id) }
    let(:hold_daily_schedule2) { create(:hold_daily_schedule, hold_daily_id: hold_daily2.id) }

    let(:hold_daily) { create(:hold_daily, event_date: '2022-5-5') }
    let(:hold_daily2) { create(:hold_daily, event_date: '2022-10-10') }

    let(:seat_sale) { create(:seat_sale, :available, hold_daily_schedule_id: hold_daily_schedule.id) }

    context 'HTTPステータスとレスポンスのjson属性について' do
      it 'HTTPステータスが200であること' do
        seat_sale_index
        expect(response).to have_http_status(:ok)
      end

      it 'jsonは::SeatSaleSerializerの属性を持つハッシュであること' do
        seat_sale
        seat_sale_index
        json = JSON.parse(response.body)
        attributes = ::SeatSaleSerializer._attributes
        json['seatSales'].all? { |hash| expect(hash.keys).to match_array(attributes.map { |key| key.to_s.camelize(:lower) }) }
      end

      it 'ticket_countは売り切れステータスの合計が返ること' do
        seat_sale
        seat_sale_index
        json = JSON.parse(response.body)
        expect(json['seatSales'][0]['ticketCount']).to eq(seat_sale.tickets.count(&:sold?))
      end
    end

    context '承認前seat_sale一覧のリクエストがある場合' do
      subject(:seat_sale_index) { get admin_hold_dailies_seat_sales_url(format: :json, event_date: hold_daily.event_date) + '?type=before_sale' }

      before do
        create_list(:seat_sale, 2, hold_daily_schedule_id: hold_daily_schedule.id)
      end

      it '承認前seat_saleのみレスポンスとして返す' do
        seat_sale_index
        json = JSON.parse(response.body)
        expect(json['seatSales'][0]['salesStatus']).to eq 'before_sale'
        expect(json['seatSales'].size).to eq(2)
      end
    end

    context '販売中seat_sale一覧のリクエストがある場合' do
      subject(:seat_sale_index) { get admin_hold_dailies_seat_sales_url(format: :json, event_date: hold_daily.event_date) + '?type=on_sale' }

      before do
        create_list(:seat_sale, 2, sales_status: 'on_sale', hold_daily_schedule_id: hold_daily_schedule.id)
      end

      it '販売中seat_saleのみレスポンスとして返す' do
        seat_sale_index
        json = JSON.parse(response.body)
        expect(json['seatSales'][0]['salesStatus']).to eq 'on_sale'
        expect(json['seatSales'].size).to eq(2)
      end
    end

    context 'すべてのseat_sale一覧のリクエストがある場合' do
      subject(:seat_sale_index) { get admin_hold_dailies_seat_sales_url(format: :json, event_date: hold_daily.event_date) }

      before do
        create_list(:seat_sale, 2, hold_daily_schedule_id: hold_daily_schedule.id)
        create_list(:seat_sale, 2, :available, hold_daily_schedule_id: hold_daily_schedule.id)
      end

      it 'すべてのseat_saleについてレスポンスとして返す' do
        seat_sale_index
        json = JSON.parse(response.body)
        expect(json['seatSales'].size).to eq(4)
      end
    end

    context 'event_dateに一致するseat_sale一覧のリクエストがある場合' do
      subject(:seat_sale_index) { get admin_hold_dailies_seat_sales_url(format: :json, event_date: hold_daily.event_date) }

      before do
        create_list(:seat_sale, 2, hold_daily_schedule_id: hold_daily_schedule.id)
        create_list(:seat_sale, 2, :available, hold_daily_schedule_id: hold_daily_schedule.id)
        create_list(:seat_sale, 2, hold_daily_schedule_id: hold_daily_schedule2.id)
      end

      it 'event_dateに一致するseat_saleのみレスポンスとして返す' do
        seat_sale_index
        json = JSON.parse(response.body)
        expect(json['seatSales'].map { |j| j['id'] }.sort).to eq(hold_daily_schedule.seat_sales.ids.sort)
      end
    end

    context 'paginationの設定で1ページ毎に表示する最大値を10としている場合' do
      subject(:seat_sale_index) { get admin_hold_dailies_seat_sales_url(format: :json, event_date: hold_daily.event_date) }

      before do
        create_list(:seat_sale, 20, hold_daily_schedule_id: hold_daily_schedule.id)
      end

      it '最大で返すクーポン数は10個(paginationを使っているため)' do
        seat_sale_index
        json = JSON.parse(response.body)
        expect(json['seatSales'].size).to eq(10)
      end
    end
  end

  describe 'on_sale POST /admin/seat_sales/on_sale' do
    subject(:seat_sale_on_sale) { put '/admin/seat_sales/on_sale', params: { ids: [seat_sale.id] } }

    let(:seat_sale) { create(:seat_sale) }

    context '販売承認が一つのseat_sale場合' do
      it '販売承認されていること' do
        seat_sale_on_sale
        expect(SeatSale.first.sales_status).to eq 'on_sale'
        expect(SeatSale.count).to eq 1
      end
    end

    context '販売承認が複数のseat_sale場合' do
      subject(:seat_sale_on_sale) { put '/admin/seat_sales/on_sale', params: { ids: [seat_sale_0.id, seat_sale_1.id] } }

      let(:seat_sale_0) { create(:seat_sale, :available) }
      let(:seat_sale_1) { create(:seat_sale, :available) }

      it '販売承認されていること' do
        seat_sale_on_sale
        expect(SeatSale.first.sales_status).to eq 'on_sale'
        expect(SeatSale.second.sales_status).to eq 'on_sale'
        expect(SeatSale.count).to eq 2
      end
    end

    context '販売中のseat_sale場合' do
      let(:seat_sale) { create(:seat_sale, sales_status: 'on_sale') }

      it 'エラーが発生すること' do
        seat_sale_on_sale
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('チケットは既に販売中です')
      end
    end

    context '販売中止のseat_sale場合' do
      let(:seat_sale) { create(:seat_sale, sales_status: 'discontinued') }

      it 'エラーが発生すること' do
        seat_sale_on_sale
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('チケットが販売中止されています')
      end
    end

    context '承認する際に開催の開催年度がない場合' do
      before do
        seat_sale
        Hold.first.update_attribute(:promoter_year, nil)
      end

      it '販売承認されていないこと' do
        seat_sale_on_sale
        expect(SeatSale.first.sales_status).to eq 'before_sale'
        expect(SeatSale.count).to eq 1
      end

      it 'エラーが発生すること' do
        seat_sale_on_sale
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('開催年度がありません')
      end
    end

    context '承認する際に開催のシーズンがない場合' do
      before do
        seat_sale
        Hold.first.update_attribute(:period, nil)
      end

      it '販売承認されていないこと' do
        seat_sale_on_sale
        expect(SeatSale.first.sales_status).to eq 'before_sale'
        expect(SeatSale.count).to eq 1
      end

      it 'エラーが発生すること' do
        seat_sale_on_sale
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('シーズンがありません')
      end
    end

    context '承認する際に開催のラウンドがない場合' do
      before do
        seat_sale
        Hold.first.update_attribute(:round, nil)
      end

      it '販売承認されていないこと' do
        seat_sale_on_sale
        expect(SeatSale.first.sales_status).to eq 'before_sale'
        expect(SeatSale.count).to eq 1
      end

      it 'エラーが発生すること' do
        seat_sale_on_sale
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('ラウンドがありません')
      end
    end
  end

  describe 'show GET /admin/seat_sales/:id' do
    subject(:show_seat_sales) { get admin_seat_sale_url(id: seat_sale.id) }

    let(:seat_sale) { create(:seat_sale, template_seat_sale: template_seat_sale) }
    let(:template_seat_sale) { create(:template_seat_sale) }

    before do
      create_list(:template_seat_type, 3, :with_template_seat_type_options, template_seat_sale: template_seat_sale)
    end

    it 'renders a successful response' do
      show_seat_sales
      expect(response).to be_successful
    end

    # 期待する属性の配列
    seat_sale_serializer_attributes = %w[id salesStatus holdNameJp salesStartAt salesEndAt dailyNo admissionProgress salesProgress admissionAvailableAt admissionCloseAt eventDate refundAt]

    it 'jsonは::SeatSaleSerializerの属性を持つハッシュであること' do
      get admin_seat_sale_url(id: seat_sale.id)
      json = JSON.parse(response.body)
      expect(json.keys).to match_array(seat_sale_serializer_attributes)
    end
  end

  describe 'new GET /admin/seat_sales/new' do
    subject(:new_seat_sales) { get new_admin_seat_sale_url, params: params }

    let!(:hold_daily_1_before_held) { create(:hold_daily, daily_status: 'before_held', event_date: Time.zone.today) }
    let!(:hold_daily_schedule_1_before_held) { create(:hold_daily_schedule, hold_daily: hold_daily_1_before_held) }

    let!(:hold_daily_2_being_held) { create(:hold_daily, daily_status: 'being_held') }

    let!(:hold_daily_3_yesterday) { create(:hold_daily, daily_status: 'before_held', event_date: Time.zone.yesterday) }

    let!(:available_template_seat_sale) { create(:template_seat_sale, status: :available) }

    before do
      create(:hold_daily_schedule, hold_daily: hold_daily_2_being_held)
      create(:hold_daily_schedule, hold_daily: hold_daily_3_yesterday)
      create(:template_seat_sale, status: :unavailable)
    end

    context 'リクエストパラメータを指定しない場合' do
      let(:params) { nil }

      it 'daily_statusが「開催前」と今日以降のみの開催デイリースケジュール一覧を出力する' do
        new_seat_sales
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['holdDailySchedules'][0].keys).to match_array(%w[id name])
        expect(json['holdDailySchedules'].map { |hold_daily_schedule| hold_daily_schedule['id'] }).to eq([hold_daily_schedule_1_before_held.id])
      end

      it 'statusがavailableである販売テンプレートのIDとタイトルの一覧を出力する' do
        new_seat_sales
        json = JSON.parse(response.body)
        expect(json['templateSeatSales'][0].keys).to match_array(%w[id title])
        expect(json['templateSeatSales'].map { |template_seat_sale| template_seat_sale['id'] }).to eq([available_template_seat_sale.id])
      end

      it '有効なチケット販売が存在するHoldDailyScheduleは返さない' do
        create(:seat_sale, hold_daily_schedule_id: hold_daily_schedule_1_before_held.id, template_seat_sale: available_template_seat_sale)
        new_seat_sales
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['holdDailySchedules'][0]).to eq(nil)
      end
    end

    context 'hold_daily_schedule_id, template_seat_sale_id のパラメータが入力された場合' do
      before do
        create(:template_seat_sale_schedule, template_seat_sale: available_template_seat_sale,
                                             sales_end_time: '20:00',
                                             admission_available_time: '16:00',
                                             admission_close_time: '20:30',
                                             target_hold_schedule: :first_night)
        hold_daily_1_before_held.update(hold_daily: 1, event_date: '2022/03/01')
        hold_daily_schedule_1_before_held.update(daily_no: 'am')
      end

      let!(:template_seat_sale_schedule_first_day) { create(:template_seat_sale_schedule, template_seat_sale: available_template_seat_sale, target_hold_schedule: :first_day) }

      let(:params) do
        { hold_daily_schedule_id: hold_daily_schedule_1_before_held.id,
          template_seat_sale_id: available_template_seat_sale.id }
      end

      it 'パラメータで指定したholdDailyScheduleのidとnameが出力される' do
        new_seat_sales
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['holdDailySchedule']['id']).to eq(hold_daily_schedule_1_before_held.id)
        expect(json['holdDailySchedule']['name']).to eq("デイ #{hold_daily_1_before_held.reload.event_date.strftime('%Y/%m/%d')}(火) #{hold_daily_1_before_held.hold.hold_name_jp}")
      end

      it 'パラメータで指定したtemplateSeatSaleのIDとタイトルが出力される' do
        new_seat_sales
        json = JSON.parse(response.body)
        expect(json['templateSeatSale']['id']).to eq(available_template_seat_sale.id)
        expect(json['templateSeatSale']['title']).to eq(available_template_seat_sale.title)
      end

      it 'salesStartAtは現時刻が出力される' do
        current_datetime = Time.zone.now

        travel_to(current_datetime) do
          new_seat_sales
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json['salesStartAt']).to eq(current_datetime.strftime('%Y/%m/%d %H:%M:%S'))
        end
      end

      it 'パラメータで指定したtemplateSeatSaleに紐づく時刻自動生成値が出力される' do
        new_seat_sales
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json['salesEndTime']).to eq(template_seat_sale_schedule_first_day.sales_end_time)
        expect(json['admissionAvailableTime']).to eq(template_seat_sale_schedule_first_day.admission_available_time)
        expect(json['admissionCloseTime']).to eq(template_seat_sale_schedule_first_day.admission_close_time)
      end
    end
  end

  describe 'create POST /admin/seat_sales' do
    subject(:create_seat_sale) { post admin_seat_sales_url, params: params }

    let!(:hold_daily) { create(:hold_daily, daily_status: 'before_held') }
    let!(:hold_daily_schedule) { create(:hold_daily_schedule, hold_daily: hold_daily) }

    let!(:template_seat_sale) { create(:template_seat_sale, status: :available) }

    let(:seat_sale) { create(:seat_sale, template_seat_sale: template_seat_sale) }
    let(:template_seat_type) { create(:template_seat_type, template_seat_sale: template_seat_sale) }
    let(:template_seat_area) { create(:template_seat_area, template_seat_sale: template_seat_sale) }

    before do
      create(:template_seat_sale_schedule, template_seat_sale: template_seat_sale,
                                           sales_end_time: '20:00',
                                           admission_available_time: '16:00',
                                           admission_close_time: '20:30',
                                           target_hold_schedule: :first_day)
      create_list(:template_seat, 2, template_seat_type: template_seat_type, template_seat_area: template_seat_area)
    end

    context '必須項目を全て含むパラメータが送られてきた場合' do
      let(:params) do
        {
          holdDailyScheduleId: hold_daily_schedule.id,
          templateSeatSaleId: template_seat_sale.id,
          salesStartAt: Time.zone.now.midnight
        }
      end

      it 'レコードが登録される' do
        expect { create_seat_sale }.to change(SeatSale, :count).by(1)
      end
    end

    context 'パラメータが不足している場合' do
      let(:params) do
        {
          holdDailyScheduleId: nil,
          templateSeatSaleId: nil,
          salesStartAt: nil
        }
      end

      it 'レコードが登録されないこと' do
        expect { create_seat_sale }.to not_change(SeatSale, :count)
        body = JSON.parse(response.body)
        expect(body['detail']).to eq('パラメータが不足しています')
      end
    end

    context 'すでにbefore_saleのseat_saleが存在する場合' do
      let(:params) do
        {
          holdDailyScheduleId: hold_daily_schedule.id,
          templateSeatSaleId: template_seat_sale.id,
          salesStartAt: Time.zone.now.midnight
        }
      end

      it 'HTTPステータスが422であること' do
        create(:seat_sale, template_seat_sale: template_seat_sale, hold_daily_schedule_id: hold_daily_schedule.id)
        create_seat_sale
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'すでにon_saleのseat_saleが存在する場合' do
      let(:params) do
        {
          holdDailyScheduleId: hold_daily_schedule.id,
          templateSeatSaleId: template_seat_sale.id,
          salesStartAt: Time.zone.now.midnight
        }
      end

      it 'HTTPステータスが422であること' do
        create(:seat_sale, :available, template_seat_sale: template_seat_sale, hold_daily_schedule_id: hold_daily_schedule.id)
        create_seat_sale
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'config_price GET /admin/seat_sales/:id/config_price' do
    subject(:show_seat_sales) { get admin_config_price_url(id: seat_sale.id) }

    let(:template_seat_sale) { create(:template_seat_sale) }
    let(:seat_sale) { create(:seat_sale, template_seat_sale_id: template_seat_sale.id) }
    let!(:not_set_template_seat_sales) { create_list(:template_seat_sale, 2) }

    before do
      create_list(:template_seat_type, 3, :with_template_seat_type_options, template_seat_sale: template_seat_sale)
    end

    it 'renders a successful response' do
      show_seat_sales
      expect(response).to be_successful
    end

    it '正しい数のseat_typeとseat_type_optionsが取得できていること' do
      show_seat_sales
      json = JSON.parse(response.body)
      template_seat_types_count = seat_sale.reload.template_seat_sale.template_seat_types.count
      template_seat_type_options_count = seat_sale.reload.template_seat_sale.template_seat_types.second.template_seat_type_options.count

      expect(json['seatSale']['templateSeatTypes'].size).to eq(template_seat_types_count)
      expect(json['seatSale']['templateSeatTypes'].second['templateSeatTypeOptions'].size).to eq(template_seat_type_options_count)
      expect(json['changeFlag']).to be_truthy
    end

    it '現在設定している販売テンプレートは除外されて出力されること' do
      show_seat_sales
      json = JSON.parse(response.body)

      expect(json['templateSeatSales'].size).to eq(not_set_template_seat_sales.count)
    end

    context 'seat_saleがbefore_sale (default) の場合' do
      it 'changeFlagはtrueを返すこと' do
        show_seat_sales
        json = JSON.parse(response.body)
        expect(json['changeFlag']).to be_truthy
      end
    end

    context 'seat_saleがbefore_sale以外の場合' do
      before do
        seat_sale.on_sale!
      end

      it 'changeFlagはfalseを返すこと' do
        show_seat_sales
        json = JSON.parse(response.body)
        expect(json['changeFlag']).to be_falsey
      end
    end
  end

  describe 'duplicate POST seat_sales/:id/change_template' do
    subject(:seat_sale_change_template) { post admin_change_template_seat_sale_url(seat_sale_id), params: params }

    let(:hold_daily_schedule) { create(:hold_daily_schedule) }
    let(:seat_sale_id) { SeatSale.find_by(hold_daily_schedule_id: hold_daily_schedule.id).id }
    let(:template_seat_sale) { create(:template_seat_sale) }
    let(:change_template_seat_sale) { create(:template_seat_sale) }
    let(:params) { { template_seat_sale_id: change_template_seat_sale.id } }

    before do
      template_seat_area = create(:template_seat_area, template_seat_sale: template_seat_sale)
      template_seat_type = create(:template_seat_type, template_seat_sale: template_seat_sale)

      10.times do |i|
        create(:master_seat, master_seat_area: template_seat_area.master_seat_area, master_seat_type: template_seat_type.master_seat_type, row: i + 1)
        create(:template_seat, template_seat_area: template_seat_area, template_seat_type: template_seat_type)
        create(:template_seat_type_option, template_seat_type: template_seat_type)
      end

      tickets_params = {
        hold_daily_schedule_id: hold_daily_schedule.id,
        template_seat_sale_id: template_seat_sale.id,
        sales_start_at: Time.zone.now,
        sales_end_at: Time.zone.now + 5.days,
        admission_available_at: Time.zone.now + 6.days,
        admission_close_at: Time.zone.now + 7.days
      }

      # コピーのための販売情報の作成
      TicketsCreator.new(tickets_params).create_all_tickets!

      # 変更さきのtemplate_seat_sale情報を作成
      template_seat_area = create(:template_seat_area, template_seat_sale: change_template_seat_sale)
      template_seat_type = create(:template_seat_type, template_seat_sale: change_template_seat_sale)

      10.times do |i|
        create(:master_seat, master_seat_area: template_seat_area.master_seat_area, master_seat_type: template_seat_type.master_seat_type, row: i + 1)
        create(:template_seat, template_seat_area: template_seat_area, template_seat_type: template_seat_type)
        create(:template_seat_type_option, template_seat_type: template_seat_type)
      end
    end

    context 'seat_saleステータスがbefore_saleの場合' do
      it 'HTTPステータスが200であること' do
        SeatSale.find(seat_sale_id).before_sale!
        seat_sale_change_template
        expect(response).to have_http_status(:ok)
      end

      it 'テンプレート変更されたseat_saleの各項目が正しくコピーされていること、sales_statuはbefore_saleであること、元のseat_saleは削除されていること' do
        original = SeatSale.find(seat_sale_id)
        original.before_sale!
        seat_sale_change_template
        change = hold_daily_schedule.seat_sales.where.not(id: original.id).first
        expect(change.template_seat_sale_id).to eq(change_template_seat_sale.id)
        expect(original.hold_daily_schedule_id).to eq(change.hold_daily_schedule_id)
        expect(original.sales_start_at).to eq(change.sales_start_at)
        expect(original.sales_end_at).to eq(change.sales_end_at)
        expect(original.admission_available_at).to eq(change.admission_available_at)
        expect(original.admission_close_at).to eq(change.admission_close_at)
        expect(change).to be_before_sale
        expect(SeatSale.find_by(id: seat_sale_id)).to be_nil
      end
    end

    context 'seat_saleが存在しない場合404が返ってくること' do
      let(:seat_sale_id) { 9999 }

      it 'HTTPステータスが404であること' do
        seat_sale_change_template
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'seat_saleのステータスがbefore_saleでない場合422が返ってくること' do
      it 'HTTPステータスが422であること' do
        SeatSale.find(seat_sale_id).on_sale!
        seat_sale_change_template
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'discontinue PUT /admin/seat_sales/bulk_refund' do
    subject(:seat_sale_bulk_refund) { put admin_bulk_refund_url(id: seat_sale.id) }

    let(:seat_sale) { create(:seat_sale, :available, sales_status: sales_status) }

    context '販売中である場合' do
      let(:sales_status) { :on_sale }

      it 'エラーが返ってくること' do
        seat_sale_bulk_refund
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('販売停止中以外のステータスで一括返金はできません。')
      end
    end

    context '販売停止中の場合' do
      let(:sales_status) { :discontinued }

      it '一括返金実行日時に値が登録され、キューが登録されること' do
        seat_sale_bulk_refund
        expect(response).to have_http_status(:ok)
        expect(seat_sale.reload.refund_at).not_to eq(nil)
        expect(Sidekiq::Queue.new.size).to eq 1
      end
    end
  end

  describe 'discontinue GET /admin/seat_sales/show_bulk_refund_result' do
    subject(:seat_sale_bulk_refund_result) { get admin_show_bulk_refund_result_url(format: :json, id: seat_sale.id) + "?refund_error=#{refund_error}" }

    let(:user) { create(:user, :with_profile) }

    let(:seat_sale) { create(:seat_sale, :available, sales_status: :discontinued, refund_at: Date.new(2021, 0o1, 0o1), refund_end_at: Date.new(2021, 0o1, 0o1)) }

    let(:coupon) { create(:coupon) }
    let(:user_coupon) { user.user_coupons.create(coupon: coupon) }

    let!(:order) { create(:order, payment: payment, seat_sale_id: seat_sale.id, refund_error_message: 'already_refunded', user_coupon_id: user_coupon.id) }
    let!(:order2) { create(:order, payment: payment2, seat_sale_id: seat_sale.id, returned_at: Date.new(2021, 0o1, 0o1)) }
    let!(:order3) { create(:order, payment: payment3, seat_sale_id: seat_sale.id, returned_at: Date.new(2021, 0o1, 0o1)) }
    let!(:order4) { create(:order, payment: payment4, seat_sale_id: seat_sale.id, refund_error_message: 'resource_not_found') }
    let(:order5) { create(:order, payment: payment5, seat_sale_id: seat_sale.id, returned_at: nil) }
    let(:order6) { create(:order, payment: nil, seat_sale_id: seat_sale.id, returned_at: nil) }

    let(:payment) { create(:payment, charge_id: 'charge_id1', payment_progress: :captured) }
    let(:payment2) { create(:payment, charge_id: 'charge_id2', payment_progress: :refunded) }
    let(:payment3) { create(:payment, charge_id: 'charge_id3', payment_progress: :refunded) }
    let(:payment4) { create(:payment, charge_id: 'charge_id4', payment_progress: :captured) }
    let(:payment5) { create(:payment, charge_id: 'charge_id5', payment_progress: :requesting_payment) }

    before do
      order5
      order6
    end

    context 'refund_errorがtrueの場合' do
      let(:refund_error) { 'true' }

      it '一括返金失敗データであること、一括返金対象外のデータは含まれないこと' do
        seat_sale_bulk_refund_result
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['refundAt']).to be_present
        expect(json['refundEndAt']).to be_present
        expect(json['refundData'][0]['id']).to eq(order.id)
        expect(json['refundData'][0]['totalPrice']).to eq(order.total_price)
        expect(json['refundData'][0]['createdAt']).to be_present
        expect(json['refundData'][0]['paymentStatus']).to eq(order.payment.payment_progress)
        expect(json['refundData'][0]['returnedAt']).to be_nil
        expect(json['refundData'][0]['usedCoupon']).to eq("#{order.coupon.title}(ID: #{order.coupon.id})")
        expect(json['refundData'][0]['refundErrorMessage']).to eq(order.refund_error_message)
        expect(json['refundData'][1]['id']).to eq(order4.id)
        expect(json['refundData'][1]['totalPrice']).to eq(order4.total_price)
        expect(json['refundData'][1]['createdAt']).to be_present
        expect(json['refundData'][1]['paymentStatus']).to eq(order4.payment.payment_progress)
        expect(json['refundData'][1]['returnedAt']).to be_nil
        expect(json['refundData'][1]['usedCoupon']).to eq('無し')
        expect(json['refundData'][1]['refundErrorMessage']).to eq(order4.refund_error_message)
        expect(json['refundData'].count).to eq(2)
      end
    end

    context 'refund_errorがfalseの場合' do
      let(:refund_error) { 'false' }

      it '一括返金の全てのデータであること' do
        seat_sale_bulk_refund_result
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['refundAt']).to be_present
        expect(json['refundEndAt']).to be_present
        expect(json['refundData'][0]['id']).to eq(order.id)
        expect(json['refundData'][0]['totalPrice']).to eq(order.total_price)
        expect(json['refundData'][0]['createdAt']).to be_present
        expect(json['refundData'][0]['paymentStatus']).to eq(order.payment.payment_progress)
        expect(json['refundData'][0]['returnedAt']).to be_nil
        expect(json['refundData'][0]['usedCoupon']).to eq("#{order.coupon.title}(ID: #{order.coupon.id})")
        expect(json['refundData'][0]['refundErrorMessage']).to eq(order.refund_error_message)
        expect(json['refundData'][1]['id']).to eq(order2.id)
        expect(json['refundData'][1]['totalPrice']).to eq(order2.total_price)
        expect(json['refundData'][1]['createdAt']).to be_present
        expect(json['refundData'][1]['paymentStatus']).to eq(order2.payment.payment_progress)
        expect(json['refundData'][1]['returnedAt']).to be_present
        expect(json['refundData'][1]['usedCoupon']).to eq('無し')
        expect(json['refundData'][1]['refundErrorMessage']).to eq(order2.refund_error_message)
        expect(json['refundData'][2]['id']).to eq(order3.id)
        expect(json['refundData'][2]['totalPrice']).to eq(order3.total_price)
        expect(json['refundData'][2]['createdAt']).to be_present
        expect(json['refundData'][2]['paymentStatus']).to eq(order3.payment.payment_progress)
        expect(json['refundData'][2]['returnedAt']).to be_present
        expect(json['refundData'][2]['usedCoupon']).to eq('無し')
        expect(json['refundData'][2]['refundErrorMessage']).to eq(order3.refund_error_message)
        expect(json['refundData'][3]['id']).to eq(order4.id)
        expect(json['refundData'][3]['totalPrice']).to eq(order4.total_price)
        expect(json['refundData'][3]['createdAt']).to be_present
        expect(json['refundData'][3]['paymentStatus']).to eq(order4.payment.payment_progress)
        expect(json['refundData'][3]['returnedAt']).to be_nil
        expect(json['refundData'][3]['usedCoupon']).to eq('無し')
        expect(json['refundData'][3]['refundErrorMessage']).to eq(order4.refund_error_message)
      end

      it 'ページネーションの確認' do
        pagination =
          {
            'current' => 1,
            'previous' => nil,
            'next' => 2,
            'pageCount' => 10,
            'limitValue' => 10,
            'pages' => 3,
            'count' => 26
          }
        20.times do |_n|
          order = create(:order, order_at: Time.zone.now, seat_sale_id: seat_sale.id)
          create(:payment, order: order)
        end

        seat_sale_bulk_refund_result
        json = JSON.parse(response.body)['pagination']
        expect(json).to eq(pagination)
      end
    end
  end

  describe 'index GET /admin/seat_sales/index_for_csv' do
    subject(:seat_sale_index_for_csv) { get admin_index_for_csv_url(format: :json) }

    let!(:discontinued_seat_sale) { create(:seat_sale, sales_status: :discontinued) }

    before do
      create(:seat_sale, sales_status: :on_sale)
      create(:seat_sale, sales_status: :before_sale)
    end

    context 'HTTPステータスとレスポンスのjson属性について' do
      it 'HTTPステータスが200であること' do
        seat_sale_index_for_csv
        expect(response).to have_http_status(:ok)
      end

      it 'jsonは::SeatSaleSerializerの属性を持つハッシュであること' do
        seat_sale_index_for_csv
        json = JSON.parse(response.body)
        attributes = ::SeatSaleSerializer._attributes
        json['seatSales'].all? { |hash| expect(hash.keys).to match_array(attributes.map { |key| key.to_s.camelize(:lower) }) }
      end

      it 'on_sale,discontinuedのseat_saleのみ帰ってきていること' do
        seat_sale_index_for_csv
        json = JSON.parse(response.body)
        expect(json['seatSales'].count).to be(2)
        expect(json['seatSales'].map { |j| j['salesStatus'] }.uniq).to match_array(%w[on_sale discontinued])
      end
    end

    context 'hold_daily_schedule_idを持たないseat_saleがある場合' do
      it '正常に終了すること' do
        discontinued_seat_sale.hold_daily_schedule.destroy
        seat_sale_index_for_csv
        expect(response).to have_http_status(:ok)
      end

      it '対象のseat_saleのみ帰ってきていること' do
        discontinued_seat_sale.hold_daily_schedule.destroy
        seat_sale_index_for_csv
        json = JSON.parse(response.body)
        expect(json['seatSales'].count).to be(1)
        expect(json['seatSales'].map { |j| j['salesStatus'] }.uniq).to match_array(%w[on_sale])
      end
    end
  end

  describe 'discontinue PUT /admin/seat_sales/bulk_transfer' do
    subject(:seat_sale_bulk_transfer) { put admin_bulk_transfer_url(id: seat_sale.id, displayable: displayable) }

    let(:seat_area_displayable_true) { create(:seat_area, seat_sale: seat_sale, displayable: true) }
    let(:seat_area_displayable_false) { create(:seat_area, seat_sale: seat_sale, displayable: false) }
    let(:seat_sale) { create(:seat_sale, :in_admission_term, :available) }
    let(:displayable) { true }

    before do
      # 販売できるエリア
      create(:ticket, seat_area: seat_area_displayable_true, status: :available)
      create(:ticket, seat_area: seat_area_displayable_true, status: :sold)
      create(:ticket, seat_area: seat_area_displayable_true, status: :not_for_sale, transfer_uuid: nil)
      # 販売できないエリア
      create(:ticket, seat_area: seat_area_displayable_false, status: :available)
      create(:ticket, seat_area: seat_area_displayable_false, status: :sold)
      create(:ticket, seat_area: seat_area_displayable_false, status: :not_for_sale, transfer_uuid: nil)
    end

    context '入場可能時間が過ぎていない場合' do
      context 'displayableがtrueの場合' do
        it '仮押さえかつ、displayableがtrueのチケット全てのtransfer_uuidが埋まること' do
          seat_sale_bulk_transfer
          seat_sale.tickets.includes(:seat_area).not_for_sale.where(seat_area: { displayable: true }).each do |ticket|
            expect(ticket.transfer_uuid).to be_present
          end
        end

        it '仮押さえではなく、displayableがfalseのチケット全てのtransfer_uuidが埋まっていないこと' do
          seat_sale_bulk_transfer
          seat_sale.tickets.includes(:seat_area).where.not(status: :not_for_sale).where(seat_area: { displayable: false }).each do |ticket|
            expect(ticket.transfer_uuid).to be_nil
          end
        end

        context 'すでにtransfer_uuidが入っているチケットがあること' do
          before do
            create(:ticket, seat_area: seat_area_displayable_true, status: :not_for_sale, transfer_uuid: SecureRandom.urlsafe_base64(32))
          end

          it 'エラーにならないこと' do
            seat_sale_bulk_transfer
            expect(response).to have_http_status(:ok)
          end
        end
      end

      context 'displayableがfalseの場合' do
        it '仮押さえかつ、displayableがfalseのチケット全てのtransfer_uuidが埋まること' do
          seat_sale_bulk_transfer
          seat_sale.tickets.includes(:seat_area).not_for_sale.where(seat_area: { displayable: false }).each do |ticket|
            expect(ticket.transfer_uuid).to be_present
          end
        end

        it '仮押さえではなく、displayableがtrueのチケット全てのtransfer_uuidが埋まっていないこと' do
          seat_sale_bulk_transfer
          seat_sale.tickets.includes(:seat_area).where.not(status: :not_for_sale).where(seat_area: { displayable: true }).each do |ticket|
            expect(ticket.transfer_uuid).to be_nil
          end
        end

        context 'すでにtransfer_uuidが入っているチケットがあること' do
          before do
            create(:ticket, seat_area: seat_area_displayable_false, status: :not_for_sale, transfer_uuid: SecureRandom.urlsafe_base64(32))
          end

          it 'エラーにならないこと' do
            seat_sale_bulk_transfer
            expect(response).to have_http_status(:ok)
          end
        end
      end
    end

    context '入場可能時間が過ぎている場合' do
      before do
        seat_sale.update_columns(admission_close_at: Time.zone.now - 1.day)
      end

      it 'エラーが返ること' do
        seat_sale_bulk_transfer
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('入場可能時間が過ぎた販売は譲渡URLが発行できません。')
      end
    end
  end

  describe 'GET admin/seat_sales/:id/export_csv' do
    subject(:seat_sales_transfer_export_csv) do
      get admin_transfer_export_csv_url(seat_sale.id, format: :json), params: { displayable: displayable }
    end

    let(:displayable_false_master_seat_area) { create(:master_seat_area, sub_code: 'z', position: 'ユニットだよ') }
    let(:seat_area_displayable_true) { create(:seat_area, seat_sale: seat_sale, displayable: true) }
    let(:seat_area_displayable_false) { create(:seat_area, seat_sale: seat_sale, displayable: false, master_seat_area: displayable_false_master_seat_area) }
    let(:seat_sale) { create(:seat_sale, :in_admission_term, :available) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:master_seat_unit) { create(:master_seat_unit) }
    let(:displayable) { true }
    let(:target_ticket) { create(:ticket, seat_area: seat_area_displayable_true, seat_type: seat_type, status: :sold, transfer_uuid: SecureRandom.urlsafe_base64(32)) }
    let(:displayable_false_target_ticket) { create(:ticket, seat_area: seat_area_displayable_false, sales_type: :unit, seat_type: seat_type, status: :not_for_sale, master_seat_unit: master_seat_unit, transfer_uuid: SecureRandom.urlsafe_base64(32)) }

    before do
      create_list(:master_seat, 4, master_seat_unit: master_seat_unit)

      # 販売できるエリア
      create(:ticket, seat_area: seat_area_displayable_true, seat_type: seat_type, status: :available, transfer_uuid: SecureRandom.urlsafe_base64(32))
      target_ticket
      create(:ticket, seat_area: seat_area_displayable_true, seat_type: seat_type, status: :not_for_sale, transfer_uuid: SecureRandom.urlsafe_base64(32))
      create(:ticket, seat_area: seat_area_displayable_true, seat_type: seat_type, status: :available)
      create(:ticket, seat_area: seat_area_displayable_true, seat_type: seat_type, status: :sold)
      create(:ticket, seat_area: seat_area_displayable_true, seat_type: seat_type, status: :not_for_sale)
      # 販売できないエリア
      create(:ticket, seat_area: seat_area_displayable_false, seat_type: seat_type, status: :available, transfer_uuid: SecureRandom.urlsafe_base64(32))
      create(:ticket, seat_area: seat_area_displayable_false, seat_type: seat_type, status: :sold, transfer_uuid: SecureRandom.urlsafe_base64(32))
      displayable_false_target_ticket
      create(:ticket, seat_area: seat_area_displayable_false, seat_type: seat_type, status: :available)
      create(:ticket, seat_area: seat_area_displayable_false, seat_type: seat_type, status: :sold)
      create(:ticket, seat_area: seat_area_displayable_false, seat_type: seat_type, status: :not_for_sale)
    end

    context 'displayableがtrueの場合' do
      it 'HTTPステータスが200であること' do
        seat_sales_transfer_export_csv
        expect(response).to have_http_status(:ok)
      end

      it 'jsonはAdmin::CsvExportTransferTicketSerializerの属性を持つハッシュであること' do
        seat_sales_transfer_export_csv
        json = JSON.parse(response.body)
        attributes = ::Admin::CsvExportTransferTicketSerializer._attributes
        json.all? { |hash| expect(hash.keys).to match_array(attributes.map { |key| key.to_s.camelize(:lower) }) }
      end

      it '販売できるエリアで、チケットstatusがnot_for_saleで、transfer_uuidがnil以外のもののみ返ること' do
        tickets = seat_sale.tickets.includes(:seat_area).not_for_sale.where(seat_area: { displayable: true }).where.not(transfer_uuid: nil)

        seat_sales_transfer_export_csv
        json = JSON.parse(response.body)
        expect(json.count).to be(1)
        expect(json.map { |hash| hash['id'] }).to match_array(tickets.ids)
      end

      it 'seat_numberに想定する値が入っていること' do
        seat_sales_transfer_export_csv
        json = JSON.parse(response.body)
        expect(json[0]['seatNumber']).to eq(target_ticket.seat_number.to_s)
      end
    end

    context 'displayableがfalseの場合' do
      let(:displayable) { false }

      it '販売できないエリアで、チケットstatusがnot_for_saleで、transfer_uuidがnil以外のもののみ返ること' do
        tickets = seat_sale.tickets.includes(:seat_area).not_for_sale.where(seat_area: { displayable: false }).where.not(transfer_uuid: nil)

        seat_sales_transfer_export_csv
        json = JSON.parse(response.body)
        expect(json.count).to be(1)
        expect(json.map { |hash| hash['id'] }).to match_array(tickets.ids)
      end

      it 'unitの場合、席数がcountとして返ってくること' do
        seat_sales_transfer_export_csv
        json = JSON.parse(response.body)
        expect(json[0]['count']).to be(4)
      end

      it 'unitの場合、unitNameが入っていること' do
        seat_sales_transfer_export_csv
        json = JSON.parse(response.body)
        expect(json[0]['unitName']).to eq('ユニットだよ')
      end

      it '販売できないエリアの場合seat_numberの頭にsub_code+unit_nameが入っていること' do
        seat_sales_transfer_export_csv
        json = JSON.parse(response.body)
        expect(json[0]['seatNumber']).to eq("#{displayable_false_target_ticket.sub_code || ''}#{displayable_false_target_ticket.master_seat_unit&.unit_name}")
      end
    end
  end
end

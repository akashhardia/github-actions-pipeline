# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coupons', :admin_logged_in, type: :request do
  let(:coupon) { create(:coupon, approved_at: nil) }
  let(:template_coupon) { create(:template_coupon) }
  let(:seat_sale) { create(:seat_sale, :available) }
  let(:master_seat_type) { create(:master_seat_type) }
  let(:login_user) { create(:user) }

  describe 'GET /coupons' do
    subject(:coupons_index) { get admin_coupons_url(format: :json) }

    context 'HTTPステータスとレスポンスのjson属性について' do
      it 'HTTPステータスが200であること' do
        coupons_index
        expect(response).to have_http_status(:ok)
      end

      it 'jsonは::CouponSerializerの属性を持つハッシュであること' do
        coupon
        coupons_index
        json = JSON.parse(response.body)
        json['coupons'].all? { |hash| expect(hash.keys).to match_array(::CouponSerializer._attributes.map { |key| key.to_s.camelize(:lower) }) }
      end
    end

    context '未配布クーポン一覧のリクエストがある場合' do
      subject(:coupons_index) { get admin_coupons_url + '?type=non_distributed' }

      before do
        create_list(:coupon, 2, :available_coupon)
      end

      it '未配布クーポンのみレスポンスとして返す' do
        coupons_index
        json = JSON.parse(response.body)
        expect(json['coupons'].size).to eq(2)
      end
    end

    context '利用可能なクーポン一覧のリクエストがある場合' do
      subject(:coupons_index) { get admin_coupons_url + '?type=available' }

      it '利用可能なクーポンのみレスポンスとして返す' do
        coupon # このクーポンは利用停止中
        coupon1 = create(:coupon, :available_coupon)
        coupons_index
        json = JSON.parse(response.body)
        expect(json['coupons'][0]['title']).to eq coupon1.template_coupon.title
        expect(json['coupons'][0]['rate']).to eq coupon1.template_coupon.rate
        expect(json['coupons'].size).to eq(1)
      end
    end

    context 'すべてのクーポン一覧のリクエストがある場合' do
      subject(:coupons_index) { get admin_coupons_url }

      before do
        create(:coupon, :available_coupon)
      end

      it 'すべてのクーポンについてレスポンスとして返す' do
        coupon # このクーポンは利用停止中
        coupons_index
        json = JSON.parse(response.body)
        expect(json['coupons'].size).to eq(2)
      end
    end

    context 'paginationの設定で1ページ毎に表示する最大値を10としている場合' do
      subject(:coupons_index) { get admin_coupons_url }

      before do
        create_list(:coupon, 20)
      end

      it '最大で返すクーポン数は10個(paginationを使っているため)' do
        coupons_index
        json = JSON.parse(response.body)
        expect(json['coupons'].size).to eq(10)
      end
    end
  end

  describe 'GET /coupons/:id' do
    subject(:coupon_show) { get admin_coupon_url(coupon, format: :json) }

    # 期待する属性の配列
    coupon_serializer_attributes = %w[approvedAt availableEndAt canceledAt holdDailies id note rate
                                      scheduledDistributedAt seatTypes templateCouponId title userRestricted]

    it 'HTTPステータスが200であること' do
      coupon_show
      expect(response).to have_http_status(:ok)
    end

    it 'jsonは::CouponSerializerの属性を持つハッシュであること' do
      coupon_show
      json = JSON.parse(response.body)
      expect(json.keys).to match_array(coupon_serializer_attributes.map { |key| key.to_s.camelize(:lower) })
    end

    it 'クーポンにユーザー制限がある場合' do
      coupon.update(user_restricted: true)
      coupon_show
      json = JSON.parse(response.body)
      expect(json['userRestricted']).to eq true
    end

    it 'クーポンにユーザー制限がない場合（全員）' do
      coupon.update(user_restricted: false)
      coupon_show
      json = JSON.parse(response.body)
      expect(json['userRestricted']).to eq false
    end

    context '利用可能な開催制限がある場合' do
      let!(:coupon_hold_daily_condition) { create(:coupon_hold_daily_condition, coupon: coupon) }

      it 'holdDailiesが存在すること' do
        coupon_show
        json = JSON.parse(response.body)
        expect(json['holdDailies'].size).to eq(1)
        expect(json['holdDailies'].first.keys).to include 'id'
        expect(json['holdDailies'].first.keys).to include 'name'
      end

      context 'デイ開催の場合' do
        before do
          coupon_hold_daily_condition.hold_daily_schedule.update(daily_no: 'am')
          coupon_hold_daily_condition.hold_daily_schedule.hold_daily.update(event_date: '2022/08/20')
          coupon_hold_daily_condition.hold_daily_schedule.hold.update(hold_name_jp: 'テスト開催')
        end

        let(:expect_name) { 'デイ 2022/08/20(土) テスト開催' }

        it 'nameが期待する形式で表示されること' do
          coupon_show
          json = JSON.parse(response.body)
          expect(response).to have_http_status(:ok)
          expect(json['holdDailies'][0]['name']).to eq(expect_name)
        end
      end

      context 'ナイト開催の場合' do
        before do
          coupon_hold_daily_condition.hold_daily_schedule.update(daily_no: 'pm')
          coupon_hold_daily_condition.hold_daily_schedule.hold_daily.update(event_date: '2022/08/20')
          coupon_hold_daily_condition.hold_daily_schedule.hold.update(hold_name_jp: 'テスト開催')
        end

        let(:expect_name) { 'ナイト 2022/08/20(土) テスト開催' }

        it 'nameが期待する形式で表示されること' do
          coupon_show
          json = JSON.parse(response.body)
          expect(json['holdDailies'][0]['name']).to eq(expect_name)
        end
      end
    end

    it '利用可能な席種' do
      create(:coupon_seat_type_condition, coupon: coupon)
      coupon_show
      json = JSON.parse(response.body)
      expect(json['seatTypes'].size).to eq(1)
      expect(json['seatTypes'].first.keys).to include 'id'
      expect(json['seatTypes'].first.keys).to include 'name'
    end
  end

  describe 'GET /new_admin_coupon' do
    subject(:new_coupon) { get(new_admin_coupon_path) }

    context '有効なseat_saleとmaster_seat_typeのデータがある場合' do
      before do
        create(:seat_sale, :available)
        create(:master_seat_type)
      end

      it 'クーポン付与可能な開催情報(hold_daily)と席種の一覧が取得できる' do
        new_coupon
        res = JSON.parse(response.body)
        expect(res['holdDailySchedules'][0].keys).to eq %w[id name]
        expect(res['masterSeatTypes'][0].keys).to eq %w[id name]
        expect(response).to have_http_status(:ok)
      end
    end

    context '未承認で販売終了前のseat_saleとmaster_seat_typeのデータがある場合' do
      before do
        create(:seat_sale, :in_term, sales_status: :before_sale)
        create(:master_seat_type)
      end

      it 'クーポン付与可能な開催情報(hold_daily)と席種の一覧が取得できる' do
        new_coupon
        res = JSON.parse(response.body)
        expect(res['holdDailySchedules'][0].keys).to eq %w[id name]
        expect(res['masterSeatTypes'][0].keys).to eq %w[id name]
        expect(response).to have_http_status(:ok)
      end
    end

    context '有効なseat_saleとmaster_seat_typeのデータが無い場合' do
      it '空の配列を返す' do
        new_coupon
        res = JSON.parse(response.body)
        expect(res['holdDailySchedules'][0]).to eq nil
        expect(res['masterSeatTypes'][0]).to eq nil
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST /admin_coupons' do
    subject(:create_coupon) { post admin_coupons_url, params: params }

    before do
      create(:user, sixgram_id: 1)
      create(:user, sixgram_id: 2)
      create(:user, sixgram_id: 3)
      create(:user, sixgram_id: 4)
      create(:user, sixgram_id: 5)
    end

    context '正常に必須項目が送られてきた時' do
      let(:params) do
        { templateCoupon: { title: template_coupon.title, rate: template_coupon.rate, note: template_coupon.rate }.to_json,
          coupon: { availableEndAt: coupon.available_end_at }.to_json,
          holdDailyScheduleIds: [seat_sale.hold_daily_schedule_id].to_json,
          masterSeatTypeIds: [master_seat_type.id].to_json }
      end

      it 'template_couponとcouponが作成される' do
        expect { create_coupon }.to change(TemplateCoupon, :count).by(1).and change(Coupon, :count).by(1)
        expect(response).to have_http_status(:ok)
      end
    end

    context 'availableEndAtが現在日時より前の日時が送られてきた時' do
      let(:params) do
        { templateCoupon: { title: template_coupon.title, rate: template_coupon.rate, note: template_coupon.rate }.to_json,
          coupon: { availableEndAt: Time.zone.now - 2.days }.to_json,
          holdDailyScheduleIds: [seat_sale.hold_daily_schedule_id].to_json,
          masterSeatTypeIds: [master_seat_type.id].to_json }
      end

      it 'エラーが返されること' do
        expect { create_coupon }.not_to change(TemplateCoupon, :count)
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['code']).to eq('not_before_available_end_at')
        expect(json['detail']).to eq('現在日時より先の日付を選択してください')
      end
    end

    context '存在しないholdDailyScheduleIdsが送られてきた時' do
      let(:params) do
        { templateCoupon: { title: template_coupon.title, rate: template_coupon.rate, note: template_coupon.rate }.to_json,
          coupon: { availableEndAt: coupon.available_end_at }.to_json,
          holdDailyScheduleIds: [seat_sale.hold_daily_schedule_id + 1].to_json,
          masterSeatTypeIds: [master_seat_type.id].to_json }
      end

      it 'エラーが返されること' do
        expect { create_coupon }.not_to change(TemplateCoupon, :count)
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['code']).to eq('not_found_hold_daily')
        expect(json['detail']).to eq('存在しない開催デイリーが含まれています')
      end
    end

    context '存在しないmasterSeatTypeIdsが送られてきた時' do
      let(:params) do
        { templateCoupon: { title: template_coupon.title, rate: template_coupon.rate, note: template_coupon.rate }.to_json,
          coupon: { availableEndAt: coupon.available_end_at }.to_json,
          holdDailyScheduleIds: [seat_sale.hold_daily_schedule_id].to_json,
          masterSeatTypeIds: [master_seat_type.id + 1].to_json }
      end

      it 'エラーが返されること' do
        expect { create_coupon }.not_to change(TemplateCoupon, :count)
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['code']).to eq('not_found_seat_type')
        expect(json['detail']).to eq('存在しない席種が含まれています')
      end
    end
  end

  describe 'POST /export_csv' do
    subject(:export_csv) { post(admin_coupons_export_csv_path, params: params) }

    let(:params) { { id: coupon.id } }

    context '対象ユーザーが確定している時(配布されている時)' do
      before do
        create(:user_coupon, coupon: coupon, user: user)
        create(:user_coupon, coupon: coupon, user: user2)
        create(:user_coupon, coupon: coupon, user: user3)
        create(:profile, user: user)
        create(:profile, user: user2)
        create(:profile, user: user3)
        create(:order, :with_ticket_and_build_reserves, user: user, order_at: Time.zone.now, user_coupon_id: user.user_coupons.create(coupon: coupon).id)
        create(:order, :with_ticket_and_build_reserves, user: user, order_at: Time.zone.now + 1.hour, user_coupon_id: user.user_coupons.create(coupon: coupon).id)
        create(:order, :with_ticket_and_build_reserves, user: user2, order_at: Time.zone.now, user_coupon_id: user2.user_coupons.create(coupon: coupon).id)
        create(:order, :with_ticket_and_build_reserves, user: user2, order_at: Time.zone.now + 1.hour, user_coupon_id: user2.user_coupons.create(coupon: coupon).id)
        create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: master_seat_type)
        create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: hold_daily_schedule)
      end

      let(:user) { create(:user) }
      let(:user2) { create(:user) }
      let(:user3) { create(:user) }
      let(:hold_daily_schedule) { create(:hold_daily_schedule) }

      it 'userテーブルの情報を取得できる、ユーザーに購入履歴がなくても取得できる' do
        export_csv
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(3)
      end
    end

    context '対象ユーザーが確定していない時(配布されていない時)' do
      it 'userテーブルの情報を取得できない' do
        export_csv
        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
        expect(json.size).to eq(0)
      end
    end
  end

  describe 'クーポンの削除' do
    subject(:coupon_destroy) { delete admin_coupon_url(cancel_possible_coupon, format: :json) }

    let(:cancel_possible_coupon) { create(:coupon, :cancel_possible_coupon) }
    let(:cancel_impossible_coupon) { create(:coupon, :available_coupon) }
    let(:canceled_coupon) { create(:coupon, :available_coupon, canceled_at: Time.zone.now - 1) }

    it 'HTTPステータスが200であること' do
      coupon_destroy
      expect(response).to have_http_status(:ok)
    end

    it '配布後は削除出来ないことを確認' do
      delete admin_coupon_url(cancel_impossible_coupon, format: :json)
      body = JSON.parse(response.body)
      expect(body['detail']).to eq('配布後は削除できません')
      expect(response).to have_http_status(:bad_request)
    end

    it 'クーポンが利用停止中の場合' do
      delete admin_coupon_url(canceled_coupon, format: :json)
      body = JSON.parse(response.body)
      expect(body['detail']).to eq('このクーポンは利用停止中です')
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'クーポンの利用停止' do
    subject(:coupon_cancel) { put cancel_admin_coupon_url(cancel_impossible_coupon, format: :json) }

    let(:cancel_impossible_coupon) { create(:coupon, :available_coupon) }
    let(:canceled_coupon) { create(:coupon, :available_coupon, canceled_at: Time.zone.now - 1) }

    it 'HTTPステータスが200であること' do
      coupon_cancel
      expect(response).to have_http_status(:ok)
    end

    it 'canceled_atの値を確認' do
      expect { coupon_cancel }.to change { Coupon.find(cancel_impossible_coupon.id).canceled_at }.from(nil)
      expect(response).to have_http_status(:ok)
    end

    it 'クーポンが利用停止中の場合' do
      put cancel_admin_coupon_url(canceled_coupon, format: :json)
      body = JSON.parse(response.body)
      expect(body['detail']).to eq('このクーポンは利用停止中です')
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'クーポンの編集' do
    subject(:coupon_update) { put admin_coupon_url(update_possible_coupon), params: params }

    let(:update_possible_coupon) { create(:coupon, :cancel_possible_coupon, approved_at: nil) }
    let(:update_impossible_coupon) { create(:coupon, :available_coupon) }
    let(:canceled_coupon) { create(:coupon, :available_coupon, canceled_at: Time.zone.now - 1) }
    let(:template_coupon_params) do
      { title: 'テスト', rate: 55, note: 'テスト' }
    end
    let(:seat_sale) { create(:seat_sale, :available) }
    let(:master_seat_type) { create(:master_seat_type) }
    let(:master_seat_type2) { create(:master_seat_type) }
    let(:hold_daily_schedule) { create(:hold_daily_schedule) }

    let(:params) do
      { templateCoupon: template_coupon_params,
        coupon: { availableEndAt: coupon.available_end_at + 1 },
        holdDailyScheduleIds: [seat_sale.hold_daily_schedule_id],
        masterSeatTypeIds: [master_seat_type.id] }
    end

    let(:params2) do
      { templateCoupon: template_coupon_params,
        coupon: { availableEndAt: coupon.available_end_at + 1 } }
    end

    let(:params3) do
      { templateCoupon: template_coupon_params,
        coupon: { availableEndAt: update_possible_coupon.available_end_at },
        holdDailyScheduleIds: [seat_sale.hold_daily_schedule_id],
        masterSeatTypeIds: [master_seat_type.id] }
    end

    it 'HTTPステータスが200であること' do
      coupon_update
      expect(response).to have_http_status(:ok)
    end

    it '指定しない開催と席種は消し、指定した対象開催と対象席種が作成されることを確認' do
      create(:coupon_hold_daily_condition, coupon: update_possible_coupon, hold_daily_schedule: hold_daily_schedule)
      create(:coupon_seat_type_condition, coupon: update_possible_coupon, master_seat_type: master_seat_type2)
      expect { put admin_coupon_url(update_possible_coupon), params: params }.to change { Coupon.find(update_possible_coupon.id).coupon_hold_daily_conditions.first.hold_daily_schedule }
        .from(update_possible_coupon.coupon_hold_daily_conditions.first.hold_daily_schedule)
        .to(seat_sale.hold_daily_schedule)
        .and change { Coupon.find(update_possible_coupon.id).coupon_seat_type_conditions.first.master_seat_type }
        .from(update_possible_coupon.coupon_seat_type_conditions.first.master_seat_type)
        .to(master_seat_type)
    end

    it '開催と席種選択してない場合は全消し' do
      create(:seat_sale, :available)
      create(:master_seat_type)
      put admin_coupon_url(update_possible_coupon), params: params2
      expect(Coupon.find(update_possible_coupon.id).coupon_hold_daily_conditions.size).to eq(0)
      expect(Coupon.find(update_possible_coupon.id).coupon_seat_type_conditions.size).to eq(0)
    end

    it 'クーポンが利用停止中の場合エラーが返る' do
      put admin_coupon_url(canceled_coupon), params: params
      body = JSON.parse(response.body)
      expect(body['detail']).to eq('利用停止のクーポンは編集できません')
      expect(response).to have_http_status(:bad_request)
    end

    it '配布後は割引率編集の場合エラーが返る' do
      put admin_coupon_url(update_impossible_coupon), params: params
      body = JSON.parse(response.body)
      expect(body['detail']).to eq('配布後は割引率の編集はできません')
      expect(response).to have_http_status(:bad_request)
    end

    context '利用終了日時の変更がないとき' do
      before { update_possible_coupon.update!(updated_at: Time.zone.now - 1.hour) }

      it 'クーポンのavailable_end_atが更新されないこと' do
        old_available_end_at = update_possible_coupon.available_end_at
        put admin_coupon_url(update_possible_coupon), params: params3
        expect(update_possible_coupon.reload.available_end_at).to eq(old_available_end_at)
      end

      it 'クーポンのupdated_atが更新されること' do
        old_updated_at = update_possible_coupon.updated_at
        put admin_coupon_url(update_possible_coupon), params: params3
        expect(update_possible_coupon.reload.updated_at).not_to eq(old_updated_at)
      end
    end
  end

  describe 'PUT :id/distribution' do
    subject(:distribution_admin_coupon) { put(distribution_admin_coupon_url(coupon.id), params: params) }

    before do
      create(:user, sixgram_id: '09090909090')
      create(:user, sixgram_id: '08080808080')
      create(:user, sixgram_id: '07070707070')
      create(:user, sixgram_id: '05050505050')
      create(:user, sixgram_id: '08080808010')
    end

    let(:upload_success_file) { '/coupons/upload_success.csv' }
    let(:upload_error_file) { '/coupons/upload_error.csv' }
    let(:upload_shift_jis_file) { '/coupons/upload_shift_jis_ver.csv' }
    let(:upload_only_header_file) { '/coupons/upload_only_header.csv' }
    let(:upload_empty_file) { '/coupons/upload_empty.csv' }
    let(:coupon) { create(:coupon, canceled_at: nil, approved_at: nil, available_end_at: Time.zone.now + 10.days) }

    context 'CSVファイルが添付された時' do
      context '正常にprofileテーブルのsixgram_idが記載されたCSVファイルと必須項目が送られてきた場合' do
        let(:distribute_at) { Time.zone.now + 3.days }
        let(:params) do
          { file: fixture_file_upload(upload_success_file, 'text/csv'),
            scheduledDistributedAt: JSON.generate(distribute_at.to_s) }
        end

        it 'user_couponsのデータが作成される' do
          expect { distribution_admin_coupon }.to change(UserCoupon, :count).by(3)
          expect(response).to have_http_status(:ok)
          expect(UserCoupon.pluck(:user_id).sort).to eq(User.where(sixgram_id: %w[09090909090 08080808080 07070707070]).pluck(:id).sort)
        end
      end

      context 'userテーブルに無いsixgram_idが記載されたCSVファイルが送信された場合' do
        let(:params) do
          { file: fixture_file_upload(upload_error_file, 'text/csv'),
            scheduledDistributedAt: JSON.generate(Time.zone.now.to_s) }
        end

        it 'user_couponsのデータは更新されない' do
          expect { distribution_admin_coupon }.to change(UserCoupon, :count).by(0)
          expect(response).to have_http_status(:bad_request)
          expect(enqueued_jobs.size).to eq 0
          json = JSON.parse(response.body)
          expect(json['detail']).to eq('存在しないユーザーの6gramIDが含まれています')
        end
      end

      context '文字コードがUTF-8でなく、Shift-JISのCSVをアップロードした場合' do
        let(:params) do
          { file: fixture_file_upload(upload_shift_jis_file, 'text/csv'),
            scheduledDistributedAt: JSON.generate(Time.zone.now.to_s) }
        end

        it 'user_couponsのデータは更新されない' do
          expect { distribution_admin_coupon }.to change(UserCoupon, :count).by(0)
          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['detail']).to eq('アップされたCSVにエラーが有ります。※CSVの文字コードはUTF-8にしてください')
        end
      end

      context 'ヘッダーのみでsixgram_idのデータが無いCSVをアップロードした場合' do
        let(:params) do
          { file: fixture_file_upload(upload_only_header_file, 'text/csv'),
            scheduledDistributedAt: JSON.generate(Time.zone.now.to_s) }
        end

        it 'user_couponsとcoupon.scheduled_distributed_atは更新されない' do
          expect { distribution_admin_coupon }.to not_change(UserCoupon, :count).and not_change { coupon.reload.scheduled_distributed_at }
          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['detail']).to eq('配布対象ユーザーがいません')
        end
      end

      context '空のCSVをアップロードした場合' do
        let(:params) do
          { file: fixture_file_upload(upload_empty_file, 'text/csv'),
            scheduledDistributedAt: JSON.generate(Time.zone.now.to_s) }
        end

        it 'user_couponsとcoupon.scheduled_distributed_atは更新されない' do
          expect { distribution_admin_coupon }.to not_change(UserCoupon, :count).and not_change { coupon.reload.scheduled_distributed_at }
          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['detail']).to eq('配布対象ユーザーがいません')
        end
      end

      context '必須項目が送られてきてない時' do
        let(:params) do
          { file: fixture_file_upload(upload_success_file, 'text/csv'),
            scheduledDistributedAt: nil }
        end

        it 'user_couponsのデータが更新されないこと' do
          expect { distribution_admin_coupon }.to change(UserCoupon, :count).by(0)
          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['detail']).to eq('配布予定日を選択してください')
        end
      end

      context 'クーポンの利用停止になっている場合' do
        let(:params) do
          { file: fixture_file_upload(upload_success_file, 'text/csv'),
            scheduledDistributedAt: JSON.generate(Time.zone.now.to_s) }
        end

        it 'user_couponsのデータが更新されないこと' do
          coupon.update(canceled_at: Time.zone.now)
          expect { distribution_admin_coupon }.to change(UserCoupon, :count).by(0)
          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['detail']).to eq('利用停止のクーポンは配布できません')
        end
      end

      context 'クーポンをすでに配布している場合' do
        let(:params) do
          { file: fixture_file_upload(upload_success_file, 'text/csv'),
            scheduledDistributedAt: JSON.generate(Time.zone.now.to_s) }
        end

        it 'user_couponsのデータが更新されないこと' do
          coupon.update(approved_at: Time.zone.now)
          expect { distribution_admin_coupon }.to change(UserCoupon, :count).by(0)
          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json['detail']).to eq('配布後のクーポンは再配布できません')
        end
      end
    end

    context 'CSVファイルが無い場合' do
      context '正常に必須項目が送られてきた時' do
        let(:params) do
          { scheduledDistributedAt: JSON.generate(Time.zone.now.to_s) }
        end

        it 'user_couponsのデータが更新される' do
          expect { distribution_admin_coupon }.to change(UserCoupon, :count).by(5)
          expect(response).to have_http_status(:ok)
        end
      end

      context '必須項目が送られてきてない時' do
        let(:params) do
          { scheduledDistributedAt: nil }
        end

        it 'user_couponsのデータが更新されないこと' do
          expect { distribution_admin_coupon }.to change(UserCoupon, :count).by(0)
          expect(response).to have_http_status(:bad_request)
          expect(enqueued_jobs.size).to eq 0
          json = JSON.parse(response.body)
          expect(json['detail']).to eq('配布予定日を選択してください')
        end
      end
    end
  end

  describe 'GET /coupons/used_coupon_count' do
    subject(:coupons_used_coupon_count) { get admin_coupons_used_coupon_count_url + query }

    context 'クエリにcoupon_idsを含んでいる場合' do
      let(:query) { "?coupon_ids=#{coupon.id}" }

      it 'HTTPステータスが200であること' do
        coupons_used_coupon_count
        expect(response).to have_http_status(:ok)
      end

      it 'jsonは期待する属性を持つハッシュであること' do
        coupons_used_coupon_count
        json = JSON.parse(response.body)
        json['coupons'].all? { |hash| expect(hash.keys).to match_array(%w[id numberOfUsedCoupons numberOfDistributedCoupons]) }
      end
    end

    context 'クエリにcoupon_idsを含んでいない場合' do
      let(:query) { '' }

      it 'HTTPステータスが400であること' do
        coupons_used_coupon_count
        body = JSON.parse(response.body)
        expect(response).to have_http_status(:bad_request)
        expect(body['detail']).to eq('coupon_idsを入力してください')
      end
    end
  end
end

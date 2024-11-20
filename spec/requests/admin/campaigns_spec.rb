# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Campaigns', :admin_logged_in, type: :request do
  describe 'キャンペーン割引一覧 GET /admin/campaigns' do
    subject(:campaigns_index) { get admin_campaigns_url(format: :json) }

    before do
      create_list(:campaign, 2, approved_at: nil)
      create_list(:campaign, 1, approved_at: Time.zone.now)
    end

    it 'HTTPステータスが200であること' do
      campaigns_index
      expect(response).to have_http_status(:ok)
    end

    it 'jsonはAdmin::CampaignSerializerの属性を持つハッシュであること' do
      # 期待する属性の配列
      campaign_serializer_attributes = %w[approvedAt code createdAt description discountRate displayable
                                          endAt holdDailySchedules id masterSeatTypes startAt terminatedAt
                                          title updatedAt usageLimit]

      campaigns_index
      json = JSON.parse(response.body)
      json['campaigns'].all? { |hash| expect(hash.keys).to match_array(campaign_serializer_attributes) }
    end

    it 'IDの降順で出力されること' do
      campaigns_index
      json = JSON.parse(response.body)
      expect(json['campaigns'][0]['id']).to be > json['campaigns'][1]['id']
    end

    context '未承認キャンペーン一覧のリクエストがある場合' do
      subject(:campaigns_index) { get admin_campaigns_url + '?type=not_approved' }

      it '未承認キャンペーンのみを返す' do
        campaigns_index
        json = JSON.parse(response.body)
        expect(json['campaigns'].size).to eq(2)
      end
    end

    context '承認済みキャンペーン一覧のリクエストがある場合' do
      subject(:campaigns_index) { get admin_campaigns_url + '?type=approved' }

      it '利用可能なキャンペーンのみを返す' do
        campaigns_index
        json = JSON.parse(response.body)
        expect(json['campaigns'].size).to eq(1)
      end
    end

    context 'typeパラメータの指定がない場合' do
      subject(:campaigns_index) { get admin_campaigns_url }

      it 'すべてのキャンペーンを返す' do
        campaigns_index
        json = JSON.parse(response.body)
        expect(json['campaigns'].size).to eq(3)
      end
    end
  end

  describe 'キャンペーン割引詳細 GET /admin/campaigns/:id' do
    subject(:campaign_show) { get admin_campaign_url(campaign.id, format: :json) }

    let(:campaign) { create(:campaign) }

    # 期待する属性の配列
    campaign_serializer_attributes = %w[approvedAt code description discountRate displayable endAt
                                        holdDailySchedules id masterSeatTypes startAt terminatedAt title usageLimit currentUsagesCount]

    it 'HTTPステータスが200であること' do
      campaign_show
      expect(response).to have_http_status(:ok)
    end

    it 'jsonはAdmin::CampaignSerializerの属性を持つハッシュであること' do
      campaign_show
      json = JSON.parse(response.body)
      expect(json.keys).to match_array(campaign_serializer_attributes.map { |key| key.to_s.camelize(:lower) })
    end

    context 'キャンペーンを使用した決済済みオーダーが存在しない場合' do
      let!(:not_captured_order) { create(:order) }

      before do
        create(:campaign_usage, campaign: campaign, order: not_captured_order)
      end

      it '0が出力される' do
        campaign_show
        json = JSON.parse(response.body)
        expect(json['currentUsagesCount']).to eq(0)
      end
    end

    context 'キャンペーンを使用した決済済みオーダーがある場合' do
      let!(:captured_order_1) { create(:order, :payment_captured) }
      let!(:captured_order_2) { create(:order, :payment_captured) }
      let!(:not_captured_order) { create(:order) }

      before do
        create(:campaign_usage, campaign: campaign, order: captured_order_1)
        create(:campaign_usage, campaign: campaign, order: captured_order_2)
        create(:campaign_usage, campaign: campaign, order: not_captured_order)
      end

      it 'キャンペーンを使用した決済済みオーダーのユーザー数が出力される' do
        campaign_show
        json = JSON.parse(response.body)
        expect(json['currentUsagesCount']).to eq(2)
      end
    end
  end

  describe 'campaignレコード新規作成用の初期データ取得 GET /admin/campaigns/new' do
    subject(:new_campaign) { get new_admin_campaign_url }

    let(:hold_daily_before_sale) { create(:hold_daily, :before_event_one_day) }
    let!(:hold_daily_schedule_before_sale) { create(:hold_daily_schedule, hold_daily: hold_daily_before_sale) }

    let(:hold_daily_on_sale) { create(:hold_daily, :today_event) }
    let!(:hold_daily_schedule_on_sale) { create(:hold_daily_schedule, hold_daily: hold_daily_on_sale) }

    let(:hold_daily_sales_end) { create(:hold_daily, :after_event) }
    let!(:hold_daily_schedule_sales_end) { create(:hold_daily_schedule, hold_daily: hold_daily_sales_end) }

    before do
      create(:seat_sale, sales_status: 'before_sale', sales_start_at: Time.zone.now.since(1.minute), hold_daily_schedule: hold_daily_schedule_before_sale)
      create(:seat_sale, sales_status: 'on_sale', sales_start_at: Time.zone.now.ago(1.minute), sales_end_at: Time.zone.now.since(1.minute), hold_daily_schedule: hold_daily_schedule_on_sale)
      create(:seat_sale, sales_status: 'on_sale', sales_start_at: Time.zone.now.ago(2.minutes), sales_end_at: Time.zone.now.ago(1.minute), hold_daily_schedule: hold_daily_schedule_sales_end)
      create_list(:master_seat_type, 2)
    end

    it '現在時刻が販売期間内かつ販売中の販売情報を持つ開催デイリースケジュール一覧を出力する' do
      new_campaign
      json = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(json['holdDailySchedules'][0].keys).to eq(%w[id name])
      expect(json['holdDailySchedules'].map { |hold_daily_schedule| hold_daily_schedule['id'] }).to eq([hold_daily_schedule_on_sale.id])
    end

    it '席種マスタ一覧を出力する' do
      new_campaign
      json = JSON.parse(response.body)
      expect(json['masterSeatTypes'][0].keys).to eq(%w[id name])
      expect(json['masterSeatTypes'].map { |master_seat_type| master_seat_type['id'] }).to eq(MasterSeatType.pluck(:id))
    end
  end

  describe 'campaignレコードの新規登録 POST /admin/campaigns' do
    subject(:create_campaign) { post admin_campaigns_url, params: params }

    let(:hold_daily_before_held) { create(:hold_daily, :before_event_one_day, daily_status: 'before_held') }
    let(:hold_daily_schedules) { create_list(:hold_daily_schedule, 2, hold_daily: hold_daily_before_held) }
    let(:master_seat_types) { create_list(:master_seat_type, 2) }

    context '必須項目（タイトル、コード値、割引率、使用ユーザー数上限）を全て含むパラメータが送られてきた場合' do
      let(:params) do
        {
          campaign: {
            title: 'キャンペーンタイトル',
            code: 'aaaaaaaaaa',
            discountRate: '10',
            usageLimit: '100',
            startAt: '2022-01-01',
            endAt: '2022-01-31'
          }.to_json,
          holdDailyScheduleIds: hold_daily_schedules.pluck(:id).to_json,
          masterSeatTypeIds: master_seat_types.pluck(:id).to_json
        }
      end

      it 'レコードが登録される' do
        expect(response).to have_http_status(:ok)
        expect { create_campaign }.to change(Campaign, :count).by(1).and \
          change(CampaignHoldDailySchedule, :count).by(hold_daily_schedules.count).and \
            change(CampaignMasterSeatType, :count).by(master_seat_types.count)
      end

      it '開始日は、"[パラメータの日付] 00:00:00"、終了日は、"[パラメータの日付] 23:59:59"で登録される' do
        create_campaign
        created_campaign = Campaign.last
        expect(created_campaign.start_at.strftime('%Y-%m-%d %H:%M:%S')).to eq("#{JSON.parse(params[:campaign])['startAt']} 00:00:00")
        expect(created_campaign.end_at.strftime('%Y-%m-%d %H:%M:%S')).to eq("#{JSON.parse(params[:campaign])['endAt']} 23:59:59")
      end
    end

    context '必須項目（タイトル、コード値、割引率）のパラメータが不足している場合' do
      # 必須のdiscountRateが不足
      let(:params) do
        { title: 'キャンペーンタイトル',
          code: 'aaaaaaaaaa',
          holdDailyScheduleIds: hold_daily_schedules.pluck(:id),
          masterSeatTypeIds: master_seat_types.pluck(:id) }
      end

      it 'レコードは登録されない' do
        expect { create_campaign }.to not_change(Campaign, :count).and not_change(CampaignHoldDailySchedule, :count).and not_change(CampaignMasterSeatType, :count)
      end
    end

    context '存在しないholdDailyScheduleIdsを含んでいる場合' do
      let(:params) do
        {
          campaign: {
            title: 'キャンペーンタイトル',
            code: 'aaaaaaaaaa',
            discountRate: '10',
            usageLimit: '100',
            startAt: '2022-01-01',
            endAt: '2022-01-31'
          }.to_json,
          holdDailyScheduleIds: ((1..10).to_a - hold_daily_schedules.pluck(:id)).first(2).to_json,
          masterSeatTypeIds: master_seat_types.pluck(:id).to_json
        }
      end

      it 'レコードは登録されない' do
        expect { create_campaign }.to not_change(Campaign, :count).and not_change(CampaignHoldDailySchedule, :count).and not_change(CampaignMasterSeatType, :count)
        body = JSON.parse(response.body)
        expect(body['detail']).to eq('存在しない開催デイリーが含まれています')
        expect(response).to have_http_status(:not_found)
      end
    end

    context '存在しないmasterSeatTypeIdsを含んでいる場合' do
      let(:params) do
        {
          campaign: {
            title: 'キャンペーンタイトル',
            code: 'aaaaaaaaaa',
            discountRate: '10',
            usageLimit: '100',
            startAt: '2022-01-01',
            endAt: '2022-01-31'
          }.to_json,
          holdDailyScheduleIds: hold_daily_schedules.pluck(:id).to_json,
          masterSeatTypeIds: ((1..10).to_a - master_seat_types.pluck(:id)).first(2).to_json
        }
      end

      it 'レコードは登録されない' do
        expect { create_campaign }.to not_change(Campaign, :count).and not_change(CampaignHoldDailySchedule, :count).and not_change(CampaignMasterSeatType, :count)
        body = JSON.parse(response.body)
        expect(body['detail']).to eq('存在しない席種が含まれています')
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'campaignレコードの更新 PUT /admin/campaigns/:id' do
    subject(:update_campaign) { put admin_campaign_url(campaign), params: params }

    let(:campaign) do
      create(:campaign,
             title: 'init_title',
             code: 'init_code',
             discount_rate: 10,
             usage_limit: 100,
             description: 'init_description',
             start_at: '2021-01-01 0:00:00',
             end_at: '2021-12-31 23:59:59',
             displayable: true)
    end

    context '未承認の場合' do
      before do
        campaign.update!(approved_at: nil)
      end

      let(:params) do
        {
          campaign: {
            title: 'new_title',
            code: 'new_code',
            discountRate: 25,
            usageLimit: 100,
            description: 'new_description',
            startAt: '2022-10-10 10:00:00',
            endAt: '2022-11-01 21:00:00',
            displayable: false
          },
          holdDailyScheduleIds: [],
          masterSeatTypeIds: []
        }
      end

      it '正常にレコードが更新される' do
        expect { update_campaign }.to change { campaign.reload.title }.from('init_title').to(params[:campaign][:title]).and \
          change { campaign.reload.code }.from('init_code').to(params[:campaign][:code]).and \
            change { campaign.reload.discount_rate }.from(10).to(params[:campaign][:discountRate]).and \
              change { campaign.reload.description }.from('init_description').to(params[:campaign][:description]).and \
                change { campaign.reload.start_at.strftime('%Y-%m-%d %H:%M:%S') }.from('2021-01-01 00:00:00').to(params[:campaign][:startAt]).and \
                  change { campaign.reload.end_at.strftime('%Y-%m-%d %H:%M:%S') }.from('2021-12-31 23:59:59').to(params[:campaign][:endAt]).and \
                    change { campaign.reload.displayable }.from(true).to(params[:campaign][:displayable])
      end
    end

    context '承認済みの場合' do
      before do
        campaign.update!(approved_at: campaign.end_at.ago(1.day))
      end

      context 'パラメータにコード値、割引率、使用ユーザー数上限、開始日、終了日に変更がある場合' do
        let(:params) do
          {
            campaign: {
              code: 'new_code',
              discountRate: 25,
              usageLimit: 999,
              startAt: '2022-10-10 10:00:00',
              endAt: '2022-11-01 21:00:00',
              title: 'new_title',
              description: 'new_description',
              displayable: false
            },
            holdDailyScheduleIds: [],
            masterSeatTypeIds: []
          }
        end

        it 'いずれのカラムも更新されない' do
          initial_campaign_values = campaign.attributes.values
          update_campaign
          updated_campaign_values = campaign.reload.attributes.values
          body = JSON.parse(response.body)
          expect(body['detail']).to eq('承認済みの場合、コード、割引率、開始日、終了日は編集できません')
          expect(response).to have_http_status(:bad_request)
          expect(updated_campaign_values).to match_array(initial_campaign_values)
        end
      end

      context 'パラメータにコード値、割引率、開始日、終了日の変更がない場合' do
        let(:params) do
          {
            campaign: {
              code: campaign.code,
              discountRate: campaign.discount_rate,
              usageLimit: campaign.usage_limit,
              startAt: campaign.start_at,
              endAt: campaign.end_at,
              title: 'new_title',
              description: 'new_description',
              displayable: false
            },
            holdDailyScheduleIds: [],
            masterSeatTypeIds: []
          }
        end

        it 'タイトル、説明、表示/非表示が更新される' do
          expect { update_campaign }.to \
            change { campaign.reload.title }.from('init_title').to(params[:campaign][:title]).and \
              change { campaign.reload.description }.from('init_description').to(params[:campaign][:description]).and \
                change { campaign.reload.displayable }.from(true).to(params[:campaign][:displayable])
        end
      end
    end

    context 'パラメータに対象の開催ID、席種マスタIDを含む場合' do
      let(:hold_daily_schedules) { create_list(:hold_daily_schedule, 3) }
      let(:master_seat_types) { create_list(:master_seat_type, 3) }
      let!(:init_campaign_hold_daily_schedules) do
        [create(:campaign_hold_daily_schedule, campaign: campaign, hold_daily_schedule: hold_daily_schedules[0]),
         create(:campaign_hold_daily_schedule, campaign: campaign, hold_daily_schedule: hold_daily_schedules[1])]
      end
      let!(:init_campaign_master_seat_types) do
        [create(:campaign_master_seat_type, campaign: campaign, master_seat_type: master_seat_types[0]),
         create(:campaign_master_seat_type, campaign: campaign, master_seat_type: master_seat_types[1])]
      end

      let(:params) do
        {
          campaign: {
            code: campaign.code,
            discount_rate: campaign.discount_rate,
            usageLimit: campaign.usage_limit,
            startAt: campaign.start_at,
            endAt: campaign.end_at,
            title: campaign.title,
            description: campaign.description,
            displayable: campaign.displayable
          },
          holdDailyScheduleIds: [hold_daily_schedules[1].id, hold_daily_schedules[2].id],
          masterSeatTypeIds: [master_seat_types[1].id, master_seat_types[2].id]
        }
      end

      it 'パラメータの開催IDリスト、席種マスタIDリストに更新される' do
        expect { update_campaign }.to \
          change { campaign.reload.hold_daily_schedules.ids }.from(init_campaign_hold_daily_schedules.pluck(:hold_daily_schedule_id)).to(params[:holdDailyScheduleIds]).and \
            change { campaign.reload.master_seat_types.ids }.from(init_campaign_master_seat_types.pluck(:master_seat_type_id)).to(params[:masterSeatTypeIds])
      end

      it 'キャンペーンのupdated_atが更新される' do
        old_updated_at = campaign.updated_at
        update_campaign
        expect(campaign.reload.updated_at).not_to eq(old_updated_at)
      end
    end
  end

  describe 'campaignレコードの削除 DELETE /admin/campaigns/:id' do
    subject(:destroy_campaign) { delete admin_campaign_url(campaign) }

    let!(:campaign) { create(:campaign) }

    context '未承認の場合' do
      let!(:hold_daily_schedule_1) { create(:hold_daily_schedule) }
      let!(:hold_daily_schedule_2) { create(:hold_daily_schedule) }
      let!(:master_seat_type_1) { create(:master_seat_type) }
      let!(:master_seat_type_2) { create(:master_seat_type) }

      before do
        create(:campaign_hold_daily_schedule, campaign: campaign, hold_daily_schedule: hold_daily_schedule_1)
        create(:campaign_hold_daily_schedule, campaign: campaign, hold_daily_schedule: hold_daily_schedule_2)
        create(:campaign_master_seat_type, campaign: campaign, master_seat_type: master_seat_type_1)
        create(:campaign_master_seat_type, campaign: campaign, master_seat_type: master_seat_type_2)

        campaign.update!(approved_at: nil)
      end

      it 'campaign, campaign_hold_daily_schedules, campaign_master_seat_typesレコードが削除されること' do
        expect { destroy_campaign }.to change(Campaign, :count).by(-1).and \
          change(CampaignHoldDailySchedule, :count).by(-2).and change(CampaignMasterSeatType, :count).by(-2)
      end
    end

    context '子レコードのcampaign_usageが存在する場合' do
      before do
        create(:campaign_usage, campaign: campaign)
      end

      it 'レコードは削除されず、エラーが返ること' do
        expect { destroy_campaign }.to not_change(Campaign, :count).and not_change(CampaignUsage, :count)
        body = JSON.parse(response.body)
        expect(body['detail']).to eq('このキャンペーンは利用済みです')
        expect(response).to have_http_status(:bad_request)
      end
    end

    context '承認済みの場合' do
      before { campaign.update!(approved_at: Time.zone.now) }

      it 'レコードは削除されず、エラーが返ること' do
        expect { destroy_campaign }.to not_change(Campaign, :count)
        body = JSON.parse(response.body)
        expect(body['detail']).to eq('承認後は削除できません')
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'campaign割引の承認 PUT /admin/campaigns/:id/approve' do
    subject(:update_approved_at) { put approve_admin_campaign_url(campaign.id, format: :json) }

    let(:campaign) do
      create(:campaign,
             title: 'init_title',
             code: 'init_code',
             discount_rate: 10,
             description: 'init_description',
             start_at: Time.zone.now - 3.days,
             end_at: Time.zone.now + 3.days,
             displayable: true)
    end

    context '未承認の場合' do
      before do
        campaign.update!(approved_at: nil)
      end

      it '現在時刻で更新されている' do
        travel_to Time.zone.now do
          expect { update_approved_at }.to change { campaign.reload.approved_at }.from(nil).to(Time.zone.now)
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context '承認済みの場合' do
      before do
        campaign.update!(approved_at: Time.zone.now)
      end

      it 'approved_atが更新されない' do
        update_approved_at
        body = JSON.parse(response.body)
        expect(body['detail']).to eq('このキャンペーンはすでに承認されています')
        expect(response).to have_http_status(:bad_request)
        expect { update_approved_at }.to not_change { campaign.reload.approved_at }
      end
    end
  end

  describe 'campaign割引の停止 PUT /admin/campaigns/:id/terminate' do
    subject(:update_terminated_at) { put terminate_admin_campaign_url(campaign.id, format: :json) }

    let(:campaign) do
      create(:campaign,
             title: 'init_title',
             code: 'init_code',
             discount_rate: 10,
             description: 'init_description',
             start_at: Time.zone.now - 3.days,
             end_at: Time.zone.now + 3.days,
             displayable: true)
    end

    context 'approved_atが存在しないとき' do
      before do
        campaign.update!(approved_at: nil)
      end

      it 'terminated_atが更新されない' do
        update_terminated_at
        body = JSON.parse(response.body)
        expect(body['detail']).to eq('このキャンペーンを先に承認してください')
        expect(response).to have_http_status(:bad_request)
        expect { update_terminated_at }.to not_change { campaign.reload.terminated_at }
      end
    end

    context 'approved_atが存在するとき' do
      before do
        campaign.update!(approved_at: Time.zone.now - 1)
      end

      it 'terminated_atが存在すると更新されない' do
        campaign.update!(terminated_at: Time.zone.now)
        update_terminated_at
        body = JSON.parse(response.body)
        expect(body['detail']).to eq('このキャンペーンはすでに停止されています')
        expect(response).to have_http_status(:bad_request)
        expect { update_terminated_at }.to not_change { campaign.reload.terminated_at }
      end

      it 'terminated_atが存在しないと現在時刻で更新されている' do
        campaign.update!(terminated_at: nil)
        travel_to Time.zone.now do
          expect { update_terminated_at }.to change { campaign.reload.terminated_at }.from(nil).to(Time.zone.now)
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe Cart, type: :model do
  let(:cart1) { described_class.new(user1) }
  let(:user1) { create(:user) }
  let(:seat_sale) { create(:seat_sale, :available) }
  let(:template_seat_type1) { create(:template_seat_type, price: 1000) }
  let(:template_seat_type2) { create(:template_seat_type, price: 2000) }
  let(:template_seat_type_box) { create(:template_seat_type, price: 15_000) }
  let(:seat_type1) { create(:seat_type, seat_sale: seat_sale, template_seat_type: template_seat_type1) }
  let(:seat_type2) { create(:seat_type, seat_sale: seat_sale, template_seat_type: template_seat_type2) }
  let(:seat_type_box1) { create(:seat_type, seat_sale: seat_sale, template_seat_type: template_seat_type_box) }
  let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
  let(:ticket1) { create(:ticket, seat_type: seat_type1, seat_area: seat_area) }
  let(:ticket2) { create(:ticket, seat_type: seat_type1, seat_area: seat_area) }
  let(:ticket3) { create(:ticket, seat_type: seat_type2, seat_area: seat_area) }
  let(:ticket4) { create(:ticket, seat_type: seat_type2, seat_area: seat_area) }
  let(:master_seat_unit) { create(:master_seat_unit) }
  let(:ticket_box1_1) { create(:ticket, seat_type: seat_type_box1, sales_type: :unit, seat_area: seat_area, master_seat_unit: master_seat_unit) }
  let(:ticket_box1_2) { create(:ticket, seat_type: seat_type_box1, sales_type: :unit, seat_area: seat_area, master_seat_unit: master_seat_unit) }

  let(:seat_type_option1) { create(:seat_type_option, seat_type: seat_type1) }
  let(:seat_type_option2) { create(:seat_type_option, seat_type: seat_type2) }
  let(:seat_type_option3) { create(:seat_type_option, seat_type: seat_type2) }
  let(:seat_type_option_box1) { create(:seat_type_option, seat_type: seat_type_box1) }

  describe '#replace_tickets' do
    subject(:replace_tickets_in_cart) { cart1.replace_tickets(orders, coupon_id, campaign_code) }

    context '空席のチケットを選択した場合' do
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: nil }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }
      let(:result) do
        {
          charge_id: nil,
          coupon_id: nil,
          campaign_code: nil,
          orders: orders
        }
      end

      it 'オーダー通りカートにチケットが追加されること' do
        replace_tickets_in_cart
        expect(cart1.ticket_orders.value).to eq(result)
      end

      it 'オーダー通りチケットが確保されていること' do
        replace_tickets_in_cart
        expect(ticket1.temporary_owner_id.value).to eq(user1.id)
        expect(ticket2.temporary_owner_id.value).to eq(user1.id)
        expect(ticket3.temporary_owner_id.value).to eq(user1.id)
      end
    end

    context '先にチケットを確保されていた場合' do
      before { replace_tickets_in_cart }

      let(:orders) do
        [
          { ticket_id: ticket3.id, option_id: nil },
          { ticket_id: ticket4.id, option_id: nil }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }
      let(:result) do
        {
          coupon_id: nil,
          orders: orders
        }
      end

      let(:cart2) { described_class.new(user2) }
      let(:user2) { create(:user) }

      it 'カートにチケットが追加されないこと' do
        cart2.replace_tickets(orders, coupon_id, campaign_code)
        expect(cart2.ticket_orders.value).to be_nil
      end

      it 'チケットの確保が上書きされないこと' do
        cart2.replace_tickets(orders, coupon_id, campaign_code)
        expect(ticket3.temporary_owner_id.value).not_to eq(user2.id)
        expect(ticket4.temporary_owner_id.value).not_to eq(user2.id)
      end

      context '一部のチケットが確保されていて失敗になった場合' do
        let(:orders2) do
          [
            { ticket_id: ticket1.id, option_id: seat_type_option1.id, coupon_id: nil },
            { ticket_id: ticket2.id, option_id: nil, coupon_id: nil },
            { ticket_id: ticket3.id, option_id: nil, coupon_id: nil },
            { ticket_id: ticket4.id, option_id: nil, coupon_id: nil }
          ]
        end

        it '途中で確保したチケットが解放されていること' do
          cart2.replace_tickets(orders2, coupon_id, campaign_code)
          expect(ticket1.temporary_owner_id.value).to be nil
          expect(ticket2.temporary_owner_id.value).to be nil
          expect(ticket3.temporary_owner_id.value).to eq(user1.id)
          expect(ticket4.temporary_owner_id.value).to eq(user1.id)
        end
      end
    end

    context '座席の再選択' do
      let(:pre_orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
          { ticket_id: ticket2.id, option_id: nil }
        ]
      end
      let(:orders) do
        [
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket4.id, option_id: nil }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      let(:result) do
        {
          charge_id: nil,
          coupon_id: nil,
          campaign_code: nil,
          orders: orders
        }
      end

      before do
        cart1.replace_tickets(pre_orders, coupon_id, campaign_code)
        replace_tickets_in_cart
      end

      it 'カートのチケットが更新されること' do
        expect(cart1.ticket_orders.value).to eq(result)
      end

      it 'オーダー通りチケットが確保されていること' do
        expect(ticket2.temporary_owner_id.value).to eq(user1.id)
        expect(ticket4.temporary_owner_id.value).to eq(user1.id)
      end

      it '変更前のオーダーで確保されたチケットが解放されていること' do
        expect(ticket1.temporary_owner_id.value).to be_nil
        expect(ticket3.temporary_owner_id.value).to be_nil
      end
    end

    context '複数ユーザーが同時に座席を確保しようとした場合' do
      let(:number_of_users) { 5 }
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      let(:users) do
        (1..number_of_users).map do
          create(:user)
        end
      end

      before do
        # テスト用のsleepコードをオン
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('DELAY_FOR_TESTING').and_return(true)

        threads = []
        users.each do |user|
          threads << Thread.new do
            cart = described_class.new(user)
            cart.replace_tickets(orders, coupon_id, campaign_code)
          end
        end

        threads.each(&:join)
      end

      it '確保できるのは1人であること' do
        winner = []
        loser = []
        users.each do |user|
          cart = described_class.new(user)
          if cart.ticket_orders.value.present?
            winner << user.id
          else
            loser << user.id
          end
        end

        expect(winner.length).to eq(1)
        expect(loser.length).to eq(number_of_users - 1)
      end

      it 'ユーザーが確保したチケットとユーザーのカート情報が一致すること' do
        user = User.find(ticket1.temporary_owner_id.value)
        cart = described_class.new(user)
        expect(cart.tickets[0]).to eq(ticket1)
      end
    end

    describe '#replace_tickets クーポン適用時' do
      before do
        create(:user_coupon, user: user1, coupon: coupon)
        create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: seat_sale.hold_daily_schedule)
        create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: seat_type.master_seat_type)
      end

      let(:coupon) { create(:coupon) }
      let(:seat_sale) { create(:seat_sale, :available) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:ticket1) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
      let(:ticket2) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
      let(:ticket3) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
      let(:seat_type_option) { create(:seat_type_option, seat_type: seat_type) }

      context '有効なクーポン情報を適用した時' do
        context 'オプションの指定が無い場合' do
          let(:orders) do
            [
              { ticket_id: ticket1.id, option_id: nil },
              { ticket_id: ticket2.id, option_id: nil },
              { ticket_id: ticket3.id, option_id: nil }
            ]
          end
          let(:coupon_id) { coupon.id }
          let(:campaign_code) { nil }
          let(:result) do
            {
              charge_id: nil,
              coupon_id: coupon.id,
              campaign_code: nil,
              orders: orders
            }
          end

          it 'カートのチケットが更新されること' do
            replace_tickets_in_cart
            expect(cart1.ticket_orders.value).to eq(result)
          end
        end

        context 'チケットのオーダー数とオプション使用数が同じ場合' do
          let(:orders) do
            [
              { ticket_id: ticket1.id, option_id: seat_type_option.id }
            ]
          end
          let(:coupon_id) { coupon.id }
          let(:campaign_code) { nil }

          it 'カートのチケットは更新されない' do
            replace_tickets_in_cart
            expect(cart1.ticket_orders.value).to eq(nil)
          end
        end

        context 'チケットのオーダー数とオプション使用数が異なる場合' do
          let(:orders) do
            [
              { ticket_id: ticket1.id, option_id: seat_type_option.id },
              { ticket_id: ticket2.id, option_id: seat_type_option.id },
              { ticket_id: ticket3.id, option_id: nil }
            ]
          end
          let(:coupon_id) { coupon.id }
          let(:campaign_code) { nil }
          let(:result) do
            {
              charge_id: nil,
              coupon_id: coupon.id,
              campaign_code: nil,
              orders: orders
            }
          end

          it 'カートのチケットが更新されること' do
            replace_tickets_in_cart
            expect(cart1.ticket_orders.value).to eq(result)
          end
        end

        context '対象のクーポンが全開催を適用対象としている場合)' do
          before do
            create(:seat_sale, :available)
          end

          let(:user_coupon) { create(:user_coupon, user: user_1, coupon: coupon_1) }
          let!(:user_1) { create(:user) }
          let(:ticket) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
          let(:orders) do
            [
              { ticket_id: ticket.id, option_id: nil }
            ]
          end
          let(:coupon_id) { coupon.id }
          let(:campaign_code) { nil }

          let(:result) do
            {
              charge_id: nil,
              coupon_id: coupon.id,
              campaign_code: nil,
              orders: orders
            }
          end

          it 'カートのチケットが更新されること' do
            replace_tickets_in_cart
            expect(cart1.ticket_orders.value).to eq(result)
          end
        end

        context '全席種をクーポン適用としている場合' do
          let(:user_coupon) { create(:user_coupon, user: user_1, coupon: coupon_1) }
          let!(:user_1) { create(:user) }
          let(:ticket) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
          let(:orders) do
            [
              { ticket_id: ticket.id, option_id: nil }
            ]
          end
          let(:coupon_id) { coupon.id }
          let(:campaign_code) { nil }
          let(:result) do
            {
              charge_id: nil,
              coupon_id: coupon.id,
              campaign_code: nil,
              orders: orders
            }
          end

          it 'カートのチケットは更新される' do
            replace_tickets_in_cart
            expect(cart1.ticket_orders.value).to eq(result)
          end
        end
      end

      context '無効なクーポン情報を適用した時' do
        context 'userが持っていないクーポンを利用した場合' do
          let(:coupon_1) { create(:coupon) }
          let(:orders) do
            [
              { ticket_id: ticket1.id, option_id: nil }
            ]
          end
          let(:coupon_id) { coupon_1.id }
          let(:campaign_code) { nil }

          it 'カートのチケットは更新されない' do
            expect(replace_tickets_in_cart).to eq(:coupon_not_found)
            expect(cart1.ticket_orders.value).to eq(nil)
          end
        end

        context '利用終了日時を過ぎていた場合' do
          let(:user_coupon) { create(:user_coupon, user: user_1, coupon: coupon_1) }
          let(:coupon) { create(:coupon, available_end_at: Time.zone.now - rand(1..9).hour) }
          let(:orders) do
            [
              { ticket_id: ticket1.id, option_id: nil }
            ]
          end
          let(:coupon_id) { coupon.id }
          let(:campaign_code) { nil }

          it 'カートのチケットは更新されない' do
            expect(replace_tickets_in_cart).to eq(:coupon_available_deadline_has_passed)
            expect(cart1.ticket_orders.value).to eq(nil)
          end
        end

        context '対象の開催(hold_daily_schedule)で無い場合(全開催をクーポン適用としていない場合)' do
          before do
            create(:seat_sale, :available)
          end

          let(:user_coupon) { create(:user_coupon, user: user_1, coupon: coupon_1) }
          let(:seat_sale_1) { create(:seat_sale, :available) }
          let(:seat_area) { create(:seat_area, seat_sale: seat_sale_1) }
          let(:seat_type) { create(:seat_type, seat_sale: seat_sale_1) }
          let(:ticket) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
          let(:orders) do
            [
              { ticket_id: ticket.id, option_id: nil }
            ]
          end
          let(:coupon_id) { coupon.id }
          let(:campaign_code) { nil }

          it 'カートのチケットは更新されない' do
            expect(replace_tickets_in_cart).to eq(:coupon_hold_daily_schedules_mismatch)
            expect(cart1.ticket_orders.value).to eq(nil)
          end
        end
      end
    end

    describe '#replace_tickets キャンペーン適用時' do
      let(:campaign) { create(:campaign, approved_at: Time.zone.now.ago(1.second)) }
      let!(:campaign_hold_daily_schedule) { create(:campaign_hold_daily_schedule, campaign: campaign, hold_daily_schedule: seat_sale.hold_daily_schedule) }
      let!(:campaign_master_seat_type) { create(:campaign_master_seat_type, campaign: campaign, master_seat_type: seat_type.master_seat_type) }

      let(:seat_sale) { create(:seat_sale, :available) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:ticket1) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
      let(:ticket2) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
      let(:ticket3) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
      let(:seat_type_option) { create(:seat_type_option, seat_type: seat_type) }

      context 'オプションの指定が無く、有効なキャンペーンコードを適用した時' do
        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { campaign.code }
        let(:result) do
          {
            charge_id: nil,
            coupon_id: nil,
            campaign_code: campaign.code,
            orders: orders
          }
        end

        it 'カートのチケットが更新されること' do
          replace_tickets_in_cart
          expect(cart1.ticket_orders.value).to eq(result)
        end
      end

      context '全チケットにオプションが選択されている場合' do
        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: seat_type_option.id },
            { ticket_id: ticket2.id, option_id: seat_type_option.id },
            { ticket_id: ticket3.id, option_id: seat_type_option.id }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { campaign.code }

        it 'エラーコード :option_and_campaign_cannot_be_used_at_same_time が上がり、カートのチケットは更新されない' do
          replace_tickets_in_cart
          expect(cart1.ticket_orders.value).to eq(nil)
        end
      end

      context 'チケットのオーダー数とオプション使用数が異なる場合' do
        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: seat_type_option.id },
            { ticket_id: ticket2.id, option_id: seat_type_option.id },
            { ticket_id: ticket3.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { campaign.code }
        let(:result) do
          {
            charge_id: nil,
            coupon_id: nil,
            campaign_code: campaign.code,
            orders: orders
          }
        end

        it 'カートのチケットが更新されること' do
          replace_tickets_in_cart
          expect(cart1.ticket_orders.value).to eq(result)
        end
      end

      context '全開催デイリースケジュールがキャンペーン適用対象となっている場合、' do
        let(:other_hold_daily_schedule) { create(:hold_daily_schedule) }
        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { campaign.code }
        let(:result) do
          {
            charge_id: nil,
            coupon_id: nil,
            campaign_code: campaign.code,
            orders: orders
          }
        end

        before do
          campaign_hold_daily_schedule.destroy!
        end

        it 'カートのチケットが更新されること' do
          replace_tickets_in_cart
          expect(cart1.ticket_orders.value).to eq(result)
        end
      end

      context '全席種がキャンペーン適用対象となっている場合、' do
        before do
          campaign_master_seat_type.destroy!
        end

        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { campaign.code }
        let(:result) do
          {
            charge_id: nil,
            coupon_id: nil,
            campaign_code: campaign.code,
            orders: orders
          }
        end

        it 'カートのチケットが更新されること' do
          replace_tickets_in_cart
          expect(cart1.ticket_orders.value).to eq(result)
        end
      end

      context '対象の開催デイリースケジュールでない場合、' do
        let(:other_hold_daily_schedule) { create(:hold_daily_schedule) }
        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { campaign.code }

        before do
          campaign_hold_daily_schedule.update!(hold_daily_schedule: other_hold_daily_schedule)
        end

        it 'エラーコード :campaign_hold_daily_schedules_mismatch が返り、カートのチケットが更新されないこと' do
          expect(replace_tickets_in_cart).to eq(:campaign_hold_daily_schedules_mismatch)
          expect(cart1.ticket_orders.value).to eq(nil)
        end
      end

      context '対象の席種でない場合、' do
        let(:other_master_seat_type) { create(:master_seat_type) }
        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { campaign.code }

        before do
          campaign_master_seat_type.update!(master_seat_type: other_master_seat_type)
        end

        it 'エラーコード :campaign_master_seat_types_mismatch が返り、カートのチケットが更新されないこと' do
          expect(replace_tickets_in_cart).to eq(:campaign_master_seat_types_mismatch)
          expect(cart1.ticket_orders.value).to eq(nil)
        end
      end

      context '利用開始日時前の場合' do
        before do
          campaign.update!(start_at: Time.zone.now.since(1.day))
        end

        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { campaign.code }

        it 'エラーコード :campaign_before_start が上がり、カートのチケットは更新されない' do
          expect(replace_tickets_in_cart).to eq(:campaign_before_start)
          expect(cart1.ticket_orders.value).to eq(nil)
        end
      end

      context '利用終了日時を過ぎていた場合' do
        before do
          campaign.update!(end_at: Time.zone.now.ago(1.second))
        end

        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { campaign.code }

        it 'エラーコード :campaign_after_end が上がり、カートのチケットは更新されない' do
          expect(replace_tickets_in_cart).to eq(:campaign_after_end)
          expect(cart1.ticket_orders.value).to eq(nil)
        end
      end

      context '未承認の場合' do
        before do
          campaign.update!(approved_at: nil)
        end

        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { campaign.code }

        it 'エラーコード :campaign_not_found が上がり、カートのチケットは更新されない' do
          expect(replace_tickets_in_cart).to eq(:campaign_not_found)
          expect(cart1.ticket_orders.value).to eq(nil)
        end
      end

      context '停止済みの場合' do
        before do
          campaign.update!(terminated_at: Time.zone.now.ago(1.second))
        end

        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { campaign.code }

        it 'エラーコード :campaign_has_terminated が上がり、カートのチケットは更新されない' do
          expect(replace_tickets_in_cart).to eq(:campaign_has_terminated)
          expect(cart1.ticket_orders.value).to eq(nil)
        end
      end

      context 'クーポンIDとキャンペーンコードが同時に入力された場合' do
        let(:coupon) { create(:coupon) }

        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil }
          ]
        end
        let(:coupon_id) { coupon.id }
        let(:campaign_code) { campaign.code }

        it 'エラーコード :coupon_and_campaign_cannot_use_at_same_time が上がり、カートのチケットは更新されない' do
          expect(replace_tickets_in_cart).to eq(:coupon_and_campaign_cannot_use_at_same_time)
          expect(cart1.ticket_orders.value).to eq(nil)
        end
      end

      context 'キャンペーンの使用ユーザー数が上限以下の値の場合、' do
        before do
          campaign.update!(usage_limit: 2)
          create(:campaign_usage, campaign: campaign, order: order_a)
        end

        let(:user_a) { create(:user) }
        let(:order_a) { create(:order, :payment_captured, user: user_a) }

        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { campaign.code }
        let(:result) do
          {
            charge_id: nil,
            coupon_id: nil,
            campaign_code: campaign.code,
            orders: orders
          }
        end

        it 'カートのチケットが更新されること' do
          replace_tickets_in_cart
          expect(cart1.ticket_orders.value).to eq(result)
        end
      end

      context 'キャンペーンの使用ユーザー数が上限に達している場合、' do
        before do
          campaign.update!(usage_limit: 2)
          create(:campaign_usage, campaign: campaign, order: order_a)
          create(:campaign_usage, campaign: campaign, order: order_b)
        end

        let(:user_a) { create(:user) }
        let(:user_b) { create(:user) }
        let(:order_a) { create(:order, :payment_captured, user: user_a) }
        let(:order_b) { create(:order, :payment_captured, user: user_b) }

        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { campaign.code }

        it 'エラーコード :campaign_usage_count_over_limit が上がり、カートのチケットは更新されない' do
          expect(replace_tickets_in_cart).to eq(:campaign_usage_count_over_limit)
          expect(cart1.ticket_orders.value).to eq(nil)
        end
      end
    end
  end

  describe '#orders' do
    let(:value) { 'test' }

    before do
      cart1.ticket_orders.value = value
    end

    it '入れた値が帰ってくること' do
      expect(cart1.orders).to eq(value)
    end
  end

  describe '#cart_ticket_ids' do
    before do
      cart1.replace_tickets(orders, coupon_id, campaign_code)
    end

    let(:orders) do
      [
        { ticket_id: ticket1.id, option_id: nil },
        { ticket_id: ticket2.id, option_id: nil },
        { ticket_id: ticket3.id, option_id: nil }
      ]
    end
    let(:coupon_id) { nil }
    let(:campaign_code) { nil }

    it '所持チケットのid配列が返ること' do
      expect(cart1.cart_ticket_ids).to eq([ticket1.id, ticket2.id, ticket3.id])
    end
  end

  describe '#recheck_ownership' do
    before do
      cart1.replace_tickets(orders, coupon_id, campaign_code)
    end

    let(:orders) do
      [
        { ticket_id: ticket1.id, option_id: nil },
        { ticket_id: ticket2.id, option_id: nil },
        { ticket_id: ticket3.id, option_id: nil }
      ]
    end
    let(:coupon_id) { nil }
    let(:campaign_code) { nil }

    context 'カート内チケットの所有権が正しくある場合' do
      it 'trueであること' do
        expect(cart1.recheck_ownership).to be true
      end
    end

    context 'カート内チケットの所有権がない場合' do
      before do
        ticket1.temporary_owner_id = -1
      end

      it 'falseであること' do
        expect(cart1.recheck_ownership).to be false
      end
    end
  end

  describe '#charge_id' do
    let(:value) { { charge_id: 'test' } }

    before do
      cart1.ticket_orders.value = value
    end

    it '入れた値が帰ってくること' do
      expect(cart1.charge_id).to eq('test')
    end
  end

  describe '#replace_cart_charge_id' do
    before do
      create(:user_coupon, user: user1, coupon: coupon)
      create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: seat_sale.hold_daily_schedule)
      create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: seat_type.master_seat_type)
      cart1.replace_tickets(orders, coupon_id, campaign_code)
    end

    let(:coupon) { create(:coupon) }
    let(:seat_sale) { create(:seat_sale, :available) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:ticket1) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
    let(:ticket2) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
    let(:ticket3) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
    let(:seat_type_option) { create(:seat_type_option, seat_type: seat_type) }
    let(:orders) do
      [
        { ticket_id: ticket1.id, option_id: nil },
        { ticket_id: ticket2.id, option_id: nil },
        { ticket_id: ticket3.id, option_id: nil }
      ]
    end
    let(:coupon_id) { coupon.id }
    let(:campaign_code) { nil }
    let(:result) do
      {
        charge_id: 'test2',
        coupon_id: coupon.id,
        campaign_code: nil,
        orders: orders
      }
    end

    context 'charge_idが渡された場合' do
      it 'カートのcharge_idが更新されること' do
        cart1.replace_tickets(orders, coupon_id, campaign_code)
        expect(cart1.ticket_orders[:charge_id]).to eq(nil)
        cart1.replace_cart_charge_id('test2')
        expect(cart1.ticket_orders.value).to eq(result)
      end
    end

    context 'charge_idがnilで渡された場合' do
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }
      let(:result) do
        {
          charge_id: nil,
          coupon_id: nil,
          campaign_code: nil,
          orders: orders
        }
      end

      it 'カートのcharge_idが更新されること' do
        cart1.replace_tickets(orders, coupon_id, campaign_code)
        expect(cart1.ticket_orders[:charge_id]).to eq(nil)
        cart1.replace_cart_charge_id(nil)
        expect(cart1.ticket_orders.value).to eq(result)
      end
    end
  end
end

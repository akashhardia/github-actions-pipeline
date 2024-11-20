# frozen_string_literal: true

require 'rails_helper'

describe PurchaseOrder, type: :model do
  let(:purchase_order) { described_class.new(cart) }
  let(:cart) { Cart.new(user) }
  let(:user) { create(:user) }
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

  describe '#find_orders_by_ticket_id' do
    subject(:find_orders_by_ticket_id) do
      cart.purchase_order.send(:find_orders_by_ticket_id, ticket_id)
    end

    before do
      cart.replace_tickets(orders, coupon_id, campaign_code)
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

    context '所持チケットのidで指定した場合' do
      let(:ticket_id) { ticket1.id }

      it '見つかること' do
        expect(find_orders_by_ticket_id).to eq({ ticket_id: ticket1.id, option_id: nil })
      end
    end

    context '所持していないチケットのidで指定した場合' do
      let(:ticket_id) { ticket4.id }

      it '見つからないこと' do
        expect(find_orders_by_ticket_id).to be_nil
      end
    end
  end

  describe '#ticket_list' do
    subject(:ticket_list) { purchase_order.send(:ticket_list) }

    context 'オプションを指定しない場合' do
      before do
        cart.replace_tickets(orders, coupon_id, campaign_code)
      end

      let(:orders) do
        [{ ticket_id: ticket1.id, option_id: nil }]
      end

      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      it 'オプション関連の項目が空であること' do
        result = ticket_list
        expect(result[0][:optionId]).to eq(nil)
        expect(result[0][:optionTitle]).to eq(nil)
        expect(result[0][:seatTypeOptionList].blank?).to be true
      end
    end

    context 'オプション価格を指定した場合' do
      before do
        cart.replace_tickets(orders, coupon_id, campaign_code)
      end

      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: seat_type_option2.id }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      it 'オプションを考慮してリストが返されること' do
        result = ticket_list
        expect(result[0][:optionId]).to eq(seat_type_option1.id)
        expect(result[0][:optionTitle]).to eq(seat_type_option1.title)
        expect(result[0][:seatTypeOptionList].nil?).to be false
      end
    end

    context '何も追加していない場合' do
      it 'リストが空であること' do
        expect(ticket_list).to eq([])
      end
    end
  end

  describe '#subtotal_price' do
    subject(:subtotal_price) { purchase_order.subtotal_price }

    context 'single席' do
      before do
        cart.replace_tickets(orders, nil, nil)
      end

      context 'optionを指定しない場合' do
        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil }
          ]
        end

        it 'Ticketの合計金額が返ってくること' do
          tickets_price = ticket1.price + ticket2.price + ticket3.price
          expect(subtotal_price).to eq(tickets_price)
        end
      end

      context 'optionを指定した場合' do
        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: seat_type_option1.id },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: seat_type_option3.id }
          ]
        end

        it 'Option価格を含めた合計金額が返ってくること' do
          tickets_price = ticket1.price + ticket2.price + ticket3.price
          options_price = seat_type_option1.price + seat_type_option3.price
          expect(subtotal_price).to eq(tickets_price + options_price)
        end
      end
    end

    context 'unit席' do
      before do
        cart.replace_tickets(orders, nil, nil)
      end

      context 'optionを指定しない場合' do
        let(:orders) do
          [
            { ticket_id: ticket_box1_1.id, option_id: nil },
            { ticket_id: ticket_box1_2.id, option_id: nil }
          ]
        end

        it 'unit席の価格が返ってくること' do
          unit_price = ticket_box1_1.price
          expect(subtotal_price).to eq(unit_price)
        end
      end

      context 'optionを指定した場合' do
        let(:orders) do
          [
            { ticket_id: ticket_box1_1.id, option_id: nil },
            { ticket_id: ticket_box1_2.id, option_id: seat_type_option_box1.id }
          ]
        end

        it 'Option価格を含めたunit席の価格が返ってくること' do
          unit_price = ticket_box1_1.price
          options_price = seat_type_option_box1.price
          expect(subtotal_price).to eq(unit_price + options_price)
        end
      end
    end

    context 'カートが空の場合' do
      it '0が返ってくること' do
        expect(subtotal_price).to eq(0)
      end
    end
  end

  describe '#total_price' do
    subject(:total_price) { purchase_order.total_price }

    let(:replace_tickets_in_cart) { cart.replace_tickets(orders, coupon_id, campaign_code) }

    context 'クーポン、キャンペーンが選択されていない場合' do
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: nil }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      it 'チケットの合計額が返ってくること' do
        replace_tickets_in_cart
        tickets_total_price = ticket1.price + ticket2.price + ticket3.price
        expect(total_price).to eq(tickets_total_price)
      end
    end

    context 'optionを指定した場合' do
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: seat_type_option3.id }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      it 'Option価格を含めた合計金額が返ってくること' do
        replace_tickets_in_cart
        tickets_total_price = ticket1.price + ticket2.price + ticket3.price
        options_total_price = seat_type_option1.price + seat_type_option3.price
        expect(total_price).to eq(tickets_total_price + options_total_price)
      end
    end

    context 'どのチケットにもオプションが付かず、クーポンを指定した場合' do
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: nil }
        ]
      end
      let(:template_coupon) { create(:template_coupon, rate: 30) }
      let(:coupon) { create(:coupon, template_coupon: template_coupon) }
      let(:coupon_id) { coupon.id }
      let(:campaign_code) { nil }

      before do
        create(:user_coupon, user: user, coupon: coupon)
      end

      it '（全チケットの合計金額）* (1 - クーポン割引率/100) の値が返ってくること' do
        replace_tickets_in_cart
        tickets_total_price = ticket1.price + ticket2.price + ticket3.price
        expect(total_price).to eq((tickets_total_price * 0.7).ceil)
      end
    end

    context 'どのチケットにもオプションが付かず、キャンペーンを指定した場合' do
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: nil }
        ]
      end
      let(:campaign) { create(:campaign, approved_at: Time.zone.now.ago(1.second), discount_rate: 25) }
      let(:coupon_id) { nil }
      let(:campaign_code) { campaign.code }

      it '（全チケットの合計金額）* (1 - キャンペーン割引率/100) の値が返ってくること' do
        replace_tickets_in_cart
        tickets_total_price = ticket1.price + ticket2.price + ticket3.price
        expect(total_price).to eq((tickets_total_price * (1 - 0.25)).ceil)
      end
    end

    context '一部のチケットにオプションが付き、クーポンを指定した場合' do
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: nil }
        ]
      end
      let(:template_coupon) { create(:template_coupon, rate: 17) }
      let(:coupon) { create(:coupon, template_coupon: template_coupon) }
      let(:coupon_id) { coupon.id }
      let(:campaign_code) { nil }

      before do
        create(:user_coupon, user: user, coupon: coupon)
      end

      it '（オプションありチケットの合計金額）+（オプション割引の合計金額）+（オプションなしチケットの合計金額）* (1 - クーポン割引率/100) の値が返ってくること' do
        replace_tickets_in_cart
        with_option_tickets_total_price = ticket1.price
        options_total_price = seat_type_option1.price
        without_option_tickets_total_price = ticket2.price + ticket3.price
        expect(total_price).to eq(with_option_tickets_total_price + options_total_price + (without_option_tickets_total_price * (1 - 0.17)).ceil)
      end
    end

    context '一部のチケットにオプションが付き、キャンペーンを指定した場合' do
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: seat_type_option3.id }
        ]
      end
      let(:campaign) { create(:campaign, approved_at: Time.zone.now.ago(1.second), discount_rate: 81) }
      let(:coupon_id) { nil }
      let(:campaign_code) { campaign.code }

      it '（オプションありチケットの合計金額）+（オプション割引の合計金額）+（オプションなしチケットの合計金額）* (1 - キャンペーン割引率/100) の値が返ってくること' do
        replace_tickets_in_cart
        with_option_tickets_total_price = ticket1.price + ticket3.price
        options_total_price = seat_type_option1.price + seat_type_option3.price
        without_option_tickets_total_price = ticket2.price
        expect(total_price).to eq(with_option_tickets_total_price + options_total_price + (without_option_tickets_total_price * (1 - 0.81)).ceil)
      end
    end
  end

  describe '#to_response_hash' do
    subject(:to_response_hash) { purchase_order.to_response_hash }

    context 'カートに追加している場合' do
      before do
        cart.replace_tickets(orders, nil, nil)
      end

      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: nil },
          { ticket_id: ticket4.id, option_id: nil }
        ]
      end

      it '関連データが返ってくること' do
        expect_data = %i[payment areaId areaName areaCode position salesType unitName unitType holdDailySchedule ticketList totalPrice couponInfo]
        expect(expect_data).to include_keys(to_response_hash.keys)
      end

      it 'holdDailyScheduleが期待する値になっていること' do
        expect_data = %i[dailyNo eventDate dayOfWeek promoterYear period round highPriorityEventCode openAt startAt]
        expect(to_response_hash[:holdDailySchedule].keys).to match_array(expect_data)
      end
    end

    context '何も追加していない場合' do
      it 'エラーが発生すること' do
        expect { to_response_hash }.to raise_error(SeatSalesFlowError)
      end
    end
  end

  describe '#coupon_discount_amount' do
    subject(:coupon_discount_amount) { purchase_order.coupon_discount_amount }

    let(:hold_daily_hash) do
      seat_sale = ticket1.seat_type.seat_sale
      {
        dailyNo: seat_sale.hold_daily_schedule.daily_no,
        eventDate: seat_sale.hold_daily.event_date,
        dayOfWeek: seat_sale.hold_daily.event_date.wday,
        holdNameJp: seat_sale.hold_daily.hold.hold_name_jp
      }
    end

    context 'クーポンを使用していない場合' do
      before do
        cart.replace_tickets(orders, nil, nil)
      end

      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: seat_type_option2.id }
        ]
      end

      it '0が返されること' do
        expect(coupon_discount_amount).to eq(0)
      end
    end

    context 'クーポンが適用された場合(オプションが一つも選択されていない場合)' do
      before do
        create(:user_coupon, user: user, coupon: coupon)
        create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: seat_sale.hold_daily_schedule)
        create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: seat_type.master_seat_type)
        cart.replace_tickets(orders, coupon_id, campaign_code)
      end

      let(:coupon) { create(:coupon, :available_coupon) }
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

      it '想定された金額が返ること' do
        expect(coupon_discount_amount).to eq((ticket1.price + ticket2.price + ticket3.price) * coupon.rate / 100.floor)
      end
    end

    context 'クーポンが適用された場合(オプションが複数選択されている場合)' do
      before do
        create(:user_coupon, user: user, coupon: coupon)
        create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: seat_sale.hold_daily_schedule)
        create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: seat_type.master_seat_type)
        cart.replace_tickets(orders, coupon_id, campaign_code)
      end

      let(:coupon) { create(:coupon, :available_coupon) }
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
          { ticket_id: ticket2.id, option_id: seat_type_option.id },
          { ticket_id: ticket3.id, option_id: nil }
        ]
      end
      let(:coupon_id) { coupon.id }
      let(:campaign_code) { nil }

      it '想定された金額が返ること' do
        expect(coupon_discount_amount).to eq((ticket1.price + ticket3.price) * coupon.rate / 100.floor)
      end
    end

    context 'クーポンが適用された場合(coupon_seat_type_conditionsが対象エリアでないクーポンの場合)' do
      before do
        create(:user_coupon, user: user, coupon: coupon)
        create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: seat_sale.hold_daily_schedule)
        create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: seat_type.master_seat_type)
        cart.replace_tickets(orders, coupon_id, campaign_code)
      end

      let(:coupon) { create(:coupon, :available_coupon) }
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
          { ticket_id: ticket2.id, option_id: seat_type_option.id },
          { ticket_id: ticket3.id, option_id: nil }
        ]
      end
      let(:coupon_id) { coupon.id }
      let(:campaign_code) { nil }

      it '0が返されること' do
        create(:master_seat_type, id: 9999)
        CouponSeatTypeCondition.first.update(master_seat_type_id: 9999)
        expect(coupon_discount_amount).to eq(0)
      end
    end

    context 'クーポンが適用された場合(unit席の場合、割引は1席分)' do
      before do
        create(:user_coupon, user: user, coupon: coupon)
        create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: seat_sale.hold_daily_schedule)
        create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: seat_type.master_seat_type)
        cart.replace_tickets(orders, coupon_id, campaign_code)
      end

      let(:master_seat_unit) { create(:master_seat_unit) }
      let(:coupon) { create(:coupon, :available_coupon) }
      let(:seat_sale) { create(:seat_sale, :available) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:ticket1) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area, master_seat_unit: master_seat_unit) }
      let(:ticket2) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area, master_seat_unit: master_seat_unit) }
      let(:ticket3) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area, master_seat_unit: master_seat_unit) }

      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: nil }
        ]
      end
      let(:coupon_id) { coupon.id }
      let(:campaign_code) { nil }

      it '想定された金額が返ること' do
        expect(coupon_discount_amount).to eq(ticket1.price * coupon.rate / 100.floor)
      end
    end
  end

  describe '#campaign_total_discount_amount' do
    subject(:campaign_total_discount_amount) { purchase_order.campaign_total_discount_amount }

    let(:replace_tickets_in_cart) { cart.replace_tickets(orders, coupon_id, campaign_code) }

    let(:seat_sale) { create(:seat_sale, :available) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:ticket1) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
    let(:ticket2) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
    let(:ticket3) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
    let(:seat_type_option) { create(:seat_type_option, seat_type: seat_type) }
    let(:hold_daily_hash) do
      seat_sale = ticket1.seat_type.seat_sale
      {
        dailyNo: seat_sale.hold_daily_schedule.daily_no,
        eventDate: seat_sale.hold_daily.event_date,
        dayOfWeek: seat_sale.hold_daily.event_date.wday,
        holdNameJp: seat_sale.hold_daily.hold.hold_name_jp
      }
    end
    let(:campaign) { create(:campaign, approved_at: Time.zone.now.ago(1.second)) }

    context 'キャンペーンを使用していない場合' do
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option.id },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: seat_type_option.id }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      it '0が返されること' do
        replace_tickets_in_cart
        expect(campaign_total_discount_amount).to eq(0)
      end
    end

    context 'キャンペーンが適用された場合(オプションが一つも選択されていない場合)' do
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: nil }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { campaign.code }

      it '想定された金額が返ること' do
        replace_tickets_in_cart
        without_option_tickets_total_price = ticket1.price + ticket2.price + ticket3.price
        expect(campaign_total_discount_amount).to eq((without_option_tickets_total_price * campaign.discount_rate / 100).floor)
      end
    end

    context 'キャンペーンが適用された場合(オプションが複数選択されている場合)' do
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
          { ticket_id: ticket2.id, option_id: seat_type_option.id },
          { ticket_id: ticket3.id, option_id: nil }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { campaign.code }

      it '想定された金額が返ること' do
        replace_tickets_in_cart
        without_option_tickets_total_price = ticket1.price + ticket3.price
        expect(campaign_total_discount_amount).to eq((without_option_tickets_total_price * campaign.discount_rate / 100).floor)
      end
    end
  end

  describe '#option_discount_amount' do
    subject(:option_discount_amount) { purchase_order.option_discount_amount }

    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }

    let(:hold_daily_hash) do
      seat_sale = ticket1.seat_type.seat_sale
      {
        dailyNo: seat_sale.hold_daily_schedule.daily_no,
        eventDate: seat_sale.hold_daily.event_date,
        dayOfWeek: seat_sale.hold_daily.event_date.wday,
        holdNameJp: seat_sale.hold_daily.hold.hold_name_jp
      }
    end

    context 'オプションを選択していない場合' do
      before do
        cart.replace_tickets(orders, nil, nil)
      end

      let(:orders) do
        [
          { ticket_id: ticket1.id, seat_type: seat_type, seat_area: seat_area, option_id: nil },
          { ticket_id: ticket2.id, seat_type: seat_type, seat_area: seat_area, option_id: nil },
          { ticket_id: ticket3.id, seat_type: seat_type, seat_area: seat_area, option_id: nil }
        ]
      end

      it '0が返されること' do
        expect(option_discount_amount).to eq(0)
      end
    end

    context 'チケットがunitの場合' do
      before do
        cart.replace_tickets(orders, nil, nil)
      end

      let(:orders) do
        [
          { ticket_id: ticket_box1_1.id, option_id: nil },
          { ticket_id: ticket_box1_2.id, option_id: nil }
        ]
      end

      it '0が返されること' do
        expect(option_discount_amount).to eq(0)
      end
    end

    context 'オプションが選択されている場合' do
      before do
        cart.replace_tickets(orders, nil, nil)
      end

      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: seat_type_option2.id }
        ]
      end

      it '想定された金額が返ること' do
        seat_type_option1.template_seat_type_option.update(price: 1000)
        seat_type_option2.template_seat_type_option.update(price: 2000)
        expect(option_discount_amount).to eq(seat_type_option1.price + seat_type_option2.price)
      end
    end
  end

  describe '#product_list' do
    subject(:product_list) { purchase_order.product_list }

    before do
      cart.replace_tickets(orders, coupon_id, campaign_code)
    end

    let(:orders) do
      [
        { ticket_id: ticket1.id, option_id: nil },
        { ticket_id: ticket2.id, option_id: nil }
      ]
    end
    let(:coupon_id) { nil }
    let(:campaign_code) { nil }

    context 'オプションを使用していない場合' do
      let(:expected_products) do
        [
          {
            amount: ticket1.price * 2,
            name: 'PIST6 入場チケット',
            quantity: 2,
            unit_price: ticket1.price,
            delivery_schedule: 'immediate',
            return_policy: 'no_return',
            note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
            note_type: 'limited_time_offers'
          }
        ]
      end

      it '期待するproductsを返すこと' do
        expect(product_list).to eq(expected_products)
      end

      it 'amountがpurchase_order.total_priceと一致すること' do
        expect(product_list.inject(0) { |result, product| result + product[:amount] }).to eq(purchase_order.total_price)
      end
    end

    context 'オプションを使用している場合' do
      before { seat_type_option1.template_seat_type_option.update(price: option_price) }

      let(:option_price) { -500 }
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: seat_type_option1.id },
        ]
      end
      let(:expected_products) do
        [
          {
            amount: (ticket1.price + seat_type_option1.price) * 2,
            name: 'PIST6 入場チケット',
            quantity: 2,
            unit_price: ticket1.price + seat_type_option1.price,
            delivery_schedule: 'immediate',
            return_policy: 'no_return',
            note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
            note_type: 'limited_time_offers'
          }
        ]
      end

      it '期待するproductsを返すこと' do
        expect(product_list).to eq(expected_products)
      end

      it 'amountがpurchase_order.total_priceと一致すること' do
        expect(product_list.inject(0) { |result, product| result + product[:amount] }).to eq(purchase_order.total_price)
      end
    end

    context '一部がオプションを使用している場合' do
      before { seat_type_option1.template_seat_type_option.update(price: option_price) }

      let(:option_price) { -500 }
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: nil },
        ]
      end
      let(:expected_products) do
        [
          {
            amount: ticket1.price + seat_type_option1.price,
            name: 'PIST6 入場チケット',
            quantity: 1,
            unit_price: ticket1.price + seat_type_option1.price,
            delivery_schedule: 'immediate',
            return_policy: 'no_return',
            note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
            note_type: 'limited_time_offers'
          },
          {
            amount: ticket2.price,
            name: 'PIST6 入場チケット',
            quantity: 1,
            unit_price: ticket2.price,
            delivery_schedule: 'immediate',
            return_policy: 'no_return',
            note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
            note_type: 'limited_time_offers'
          }
        ]
      end

      it '期待するproductsを返すこと' do
        expect(product_list).to eq(expected_products)
      end

      it 'amountの合計がpurchase_order.total_priceと一致すること' do
        expect(product_list.inject(0) { |result, product| result + product[:amount] }).to eq(purchase_order.total_price)
      end
    end

    context 'クーポンを使用している場合' do
      before do
        create(:user_coupon, user: user, coupon: coupon)
        cart.replace_tickets(orders, coupon_id, campaign_code)
      end

      let(:template_coupon) { create(:template_coupon, rate: 10) }
      let(:coupon) { create(:coupon, template_coupon: template_coupon) }
      let(:coupon_id) { coupon.id }
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
          { ticket_id: ticket2.id, option_id: nil },
        ]
      end
      let(:expected_products) do
        [
          {
            amount: (ticket1.price - (ticket1.price * coupon.rate / 100).floor) * 2,
            name: 'PIST6 入場チケット',
            quantity: 2,
            unit_price: ticket1.price - (ticket1.price * coupon.rate / 100).floor,
            delivery_schedule: 'immediate',
            return_policy: 'no_return',
            note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
            note_type: 'limited_time_offers'
          },
        ]
      end

      it '期待するproductsを返すこと' do
        expect(product_list).to eq(expected_products)
      end

      it 'amountがpurchase_order.total_priceと一致すること' do
        expect(product_list.inject(0) { |result, product| result + product[:amount] }).to eq(purchase_order.total_price)
      end
    end

    context 'オプションとクーポンを使用している場合' do
      before do
        create(:user_coupon, user: user, coupon: coupon)
        seat_type_option1.template_seat_type_option.update(price: option_price)
        cart.replace_tickets(orders, coupon_id, campaign_code)
      end

      let(:option_price) { -500 }
      let(:template_coupon) { create(:template_coupon, rate: 10) }
      let(:coupon) { create(:coupon, template_coupon: template_coupon) }
      let(:coupon_id) { coupon.id }
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: nil },
        ]
      end
      let(:expected_products) do
        [
          {
            amount: ticket1.price + option_price,
            name: 'PIST6 入場チケット',
            quantity: 1,
            unit_price: ticket1.price + option_price,
            delivery_schedule: 'immediate',
            return_policy: 'no_return',
            note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
            note_type: 'limited_time_offers'
          },
          {
            amount: ticket2.price - (ticket2.price * coupon.rate / 100).floor,
            name: 'PIST6 入場チケット',
            quantity: 1,
            unit_price: ticket2.price - (ticket2.price * coupon.rate / 100).floor,
            delivery_schedule: 'immediate',
            return_policy: 'no_return',
            note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
            note_type: 'limited_time_offers'
          },
        ]
      end

      it '期待するproductsを返すこと' do
        expect(product_list).to eq(expected_products)
      end

      it 'amountの合計がpurchase_order.total_priceと一致すること' do
        expect(product_list.inject(0) { |result, product| result + product[:amount] }).to eq(purchase_order.total_price)
      end

      context '割引後の単価が同じ場合' do
        before do
          template_coupon.update(rate: 50)
          seat_type_option1.template_seat_type_option.update(price: option_price)
        end

        let(:option_price) { -500 }
        let(:expected_products) do
          [
            {
              amount: (ticket1.price + option_price) * 2,
              name: 'PIST6 入場チケット',
              quantity: 2,
              unit_price: ticket1.price + option_price,
              delivery_schedule: 'immediate',
              return_policy: 'no_return',
              note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
              note_type: 'limited_time_offers'
            },
          ]
        end

        it '期待するproductsを返すこと' do
          expect(product_list).to eq(expected_products)
        end

        it 'amountがpurchase_order.total_priceと一致すること' do
          expect(product_list.inject(0) { |result, product| result + product[:amount] }).to eq(purchase_order.total_price)
        end
      end
    end

    context 'キャンペーンを使用している場合' do
      let(:campaign) { create(:campaign, approved_at: Time.zone.now.ago(1.second)) }
      let(:campaign_code) { campaign.code }
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
          { ticket_id: ticket2.id, option_id: nil },
        ]
      end
      let(:expected_products) do
        [
          {
            amount: (ticket1.price - (ticket1.price * campaign.discount_rate / 100).floor) * 2,
            name: 'PIST6 入場チケット',
            quantity: 2,
            unit_price: ticket1.price - (ticket1.price * campaign.discount_rate / 100).floor,
            delivery_schedule: 'immediate',
            return_policy: 'no_return',
            note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
            note_type: 'limited_time_offers'
          },
        ]
      end

      it '期待するproductsを返すこと' do
        expect(product_list).to eq(expected_products)
      end

      it 'amountがpurchase_order.total_priceと一致すること' do
        expect(product_list.inject(0) { |result, product| result + product[:amount] }).to eq(purchase_order.total_price)
      end
    end

    context 'オプションとキャンペーンを使用している場合' do
      before { seat_type_option1.template_seat_type_option.update(price: option_price) }

      let(:option_price) { -500 }
      let(:campaign) { create(:campaign, approved_at: Time.zone.now.ago(1.second)) }
      let(:campaign_code) { campaign.code }
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: nil },
        ]
      end
      let(:expected_products) do
        [
          {
            amount: ticket1.price + option_price,
            name: 'PIST6 入場チケット',
            quantity: 1,
            unit_price: ticket1.price + option_price,
            delivery_schedule: 'immediate',
            return_policy: 'no_return',
            note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
            note_type: 'limited_time_offers'
          },
          {
            amount: ticket2.price - (ticket2.price * campaign.discount_rate / 100).floor,
            name: 'PIST6 入場チケット',
            quantity: 1,
            unit_price: ticket2.price - (ticket2.price * campaign.discount_rate / 100).floor,
            delivery_schedule: 'immediate',
            return_policy: 'no_return',
            note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
            note_type: 'limited_time_offers'
          },
        ]
      end

      it '期待するproductsを返すこと' do
        expect(product_list).to eq(expected_products)
      end

      it 'amountの合計がpurchase_order.total_priceと一致すること' do
        expect(product_list.inject(0) { |result, product| result + product[:amount] }).to eq(purchase_order.total_price)
      end

      context '割引後の単価が同じ場合' do
        before do
          campaign.update(discount_rate: 50)
          seat_type_option1.template_seat_type_option.update(price: option_price)
        end

        let(:option_price) { -500 }
        let(:expected_products) do
          [
            {
              amount: (ticket1.price + option_price) * 2,
              name: 'PIST6 入場チケット',
              quantity: 2,
              unit_price: ticket1.price + option_price,
              delivery_schedule: 'immediate',
              return_policy: 'no_return',
              note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
              note_type: 'limited_time_offers'
            },
          ]
        end

        it '期待するproductsを返すこと' do
          expect(product_list).to eq(expected_products)
        end

        it 'amountがpurchase_order.total_priceと一致すること' do
          expect(product_list.inject(0) { |result, product| result + product[:amount] }).to eq(purchase_order.total_price)
        end
      end
    end

    context 'チケットがunit席の場合' do
      let(:orders) do
        [
          { ticket_id: ticket_box1_1.id, option_id: nil },
          { ticket_id: ticket_box1_2.id, option_id: nil }
        ]
      end

      context 'オプション、クーポン、キャンペーンを使用していない場合' do
        let(:expected_products) do
          [
            {
              amount: ticket_box1_1.price,
              name: 'PIST6 入場チケット',
              quantity: 1,
              unit_price: ticket_box1_1.price,
              delivery_schedule: 'immediate',
              return_policy: 'no_return',
              note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
              note_type: 'limited_time_offers'
            },
          ]
        end

        it '期待するproductsを返すこと' do
          expect(product_list).to eq(expected_products)
        end

        it 'amountがpurchase_order.total_priceと一致すること' do
          expect(product_list.inject(0) { |result, product| result + product[:amount] }).to eq(purchase_order.total_price)
        end
      end

      context 'オプションを使用している場合' do
        before { seat_type_option_box1.template_seat_type_option.update(price: option_price) }

        let(:option_price) { -500 }
        let(:orders) do
          [
            { ticket_id: ticket_box1_1.id, option_id: seat_type_option_box1.id },
            { ticket_id: ticket_box1_2.id, option_id: nil }
          ]
        end
        let(:expected_products) do
          [
            {
              amount: ticket_box1_1.price + option_price,
              name: 'PIST6 入場チケット',
              quantity: 1,
              unit_price: ticket_box1_1.price + option_price,
              delivery_schedule: 'immediate',
              return_policy: 'no_return',
              note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
              note_type: 'limited_time_offers'
            },
          ]
        end

        it '期待するproductsを返すこと' do
          expect(product_list).to eq(expected_products)
        end

        it 'amountがpurchase_order.total_priceと一致すること' do
          expect(product_list.inject(0) { |result, product| result + product[:amount] }).to eq(purchase_order.total_price)
        end
      end

      context 'クーポンを使用している場合' do
        before do
          create(:user_coupon, user: user, coupon: coupon)
          cart.replace_tickets(orders, coupon_id, campaign_code)
        end

        let(:template_coupon) { create(:template_coupon, rate: 10) }
        let(:coupon) { create(:coupon, template_coupon: template_coupon) }
        let(:coupon_id) { coupon.id }

        let(:expected_products) do
          [
            {
              amount: ticket_box1_1.price - (ticket_box1_1.price * coupon.rate / 100).floor,
              name: 'PIST6 入場チケット',
              quantity: 1,
              unit_price: ticket_box1_1.price - (ticket_box1_1.price * coupon.rate / 100).floor,
              delivery_schedule: 'immediate',
              return_policy: 'no_return',
              note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
              note_type: 'limited_time_offers'
            },
          ]
        end

        it '期待するproductsを返すこと' do
          expect(product_list).to eq(expected_products)
        end

        it 'amountがpurchase_order.total_priceと一致すること' do
          expect(product_list.inject(0) { |result, product| result + product[:amount] }).to eq(purchase_order.total_price)
        end
      end

      context 'キャンペーンを使用している場合' do
        let(:campaign) { create(:campaign, approved_at: Time.zone.now.ago(1.second)) }
        let(:campaign_code) { campaign.code }
        let(:expected_products) do
          [
            {
              amount: ticket_box1_1.price - (ticket_box1_1.price * campaign.discount_rate / 100).floor,
              name: 'PIST6 入場チケット',
              quantity: 1,
              unit_price: ticket_box1_1.price - (ticket_box1_1.price * campaign.discount_rate / 100).floor,
              delivery_schedule: 'immediate',
              return_policy: 'no_return',
              note_url: 'http://example.com/guide/ticket-guide/howto-buy/',
              note_type: 'limited_time_offers'
            },
          ]
        end

        it '期待するproductsを返すこと' do
          expect(product_list).to eq(expected_products)
        end

        it 'amountがpurchase_order.total_priceと一致すること' do
          expect(product_list.inject(0) { |result, product| result + product[:amount] }).to eq(purchase_order.total_price)
        end
      end
    end
  end
end

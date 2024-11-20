# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tickets', type: :request do
  describe 'GET sales/seat_areas/:id', :sales_logged_in do
    subject(:get_area_tickets) { get sales_url(get_area) }

    before do
      create_list(:ticket, 10, seat_area: seat_area_a, seat_type: ticket.seat_type, status: ticket_availability)
      create(:ticket, seat_area: seat_area_b, seat_type: ticket.seat_type)
    end

    let(:ticket) { create(:ticket, :sold, seat_type: seat_type, user_id: sales_logged_in_user.id) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:master_seat_area_a) { create(:master_seat_area, area_code: 'A') }
    let(:master_seat_area_b) { create(:master_seat_area, area_code: 'B') }
    let(:get_area) { seat_area_a }
    let(:seat_area_a) { create(:seat_area, seat_sale: seat_sale, master_seat_area: master_seat_area_a) }
    let(:seat_area_b) { create(:seat_area, seat_sale: seat_sale, master_seat_area: master_seat_area_b) }
    let(:ticket_availability) { :available }
    let(:seat_sale) { create(:seat_sale, :available) }

    it '指定されたエリアに対応するチケットが取得できること' do
      get_area_tickets

      master_seat_area = MasterSeatArea.find_by!(area_code: 'A')
      seat_area = SeatArea.find_by!(master_seat_area: master_seat_area)
      area_a_tickets = seat_area.tickets
      expect_hash = JSON.parse(ActiveModelSerializers::SerializableResource.new(area_a_tickets, key_transform: :camel_lower).to_json)
      json = JSON.parse(response.body)

      expect(json['seatArea']['areaCode']).to eq('A')
      json['tickets'].all? { |hash| expect(hash).to eq(expect_hash.find { |h| h['id'] == hash['id'] }) }
    end

    context '座席確保済みの場合' do
      before do
        cart = Cart.new(sales_logged_in_user)
        area_a_ticket = seat_area_a.tickets.first
        cart.replace_tickets([{ ticket_id: area_a_ticket.id, option_id: nil }], coupon_id, campaign_code)
      end

      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      context '仮押さえしたエリアと同じエリアを閲覧した場合' do
        it '仮押さえした座席の一覧が取得できていること' do
          get_area_tickets

          area_a_ticket = seat_area_a.tickets.first
          json = JSON.parse(response.body)

          expect(json['cartTickets'][0]['id']).to eq(area_a_ticket.id)
        end
      end

      context '仮押さえした席と異なるエリアを閲覧した場合' do
        let(:get_area) { seat_area_b }

        it '仮押さえした座席の一覧は空であること' do
          get_area_tickets
          json = JSON.parse(response.body)

          expect(json['cartTickets'].blank?).to be true
        end
      end
    end

    context '販売期間外の場合' do
      let(:seat_sale) { create(:seat_sale, :after_closing, sales_status: :on_sale) }

      it 'チケット一覧が取得できないこと' do
        get_area_tickets

        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'seat_sales_flow_error', 'detail' => '販売期間外です', 'status' => 400 })
      end
    end

    context '売り切れの場合' do
      let(:ticket_availability) { :sold }

      it 'チケット一覧が取得できないこと' do
        get_area_tickets

        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'seat_sales_flow_error', 'detail' => '空席ではありません', 'status' => 400 })
      end
    end

    context '販売未承認の場合' do
      let(:seat_sale) { create(:seat_sale, :in_admission_term, sales_status: :before_sale) }

      it 'チケット一覧が取得できないこと' do
        get_area_tickets

        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'seat_sales_flow_error', 'detail' => '販売が許可されていません', 'status' => 400 })
      end
    end

    context '非表示エリアの場合' do
      let(:seat_area_a) { create(:seat_area, seat_sale: seat_sale, master_seat_area: master_seat_area_a, displayable: false) }

      it 'チケット一覧が取得できないこと' do
        get_area_tickets

        json = JSON.parse(response.body)
        expect(json).to eq({ 'code' => 'seat_sales_flow_error', 'detail' => 'このエリアの表示は許可されていません', 'status' => 400 })
      end
    end

    context 'チケットのuser_idが埋まっている場合' do
      let(:get_area) { seat_area_b }
      let(:user) { create(:user) }
      let!(:temporary_hold_ticket) { create(:ticket, seat_area: seat_area_b, seat_type: ticket.seat_type, user_id: user.id, status: 'temporary_hold') }

      it 'チケットのステータスではなくsoldが返ること' do
        get_area_tickets
        json = JSON.parse(response.body)

        expect(temporary_hold_ticket.status).to eq('temporary_hold')
        expect(json['tickets'].find { |t| t['id'] == temporary_hold_ticket.id }['status']).to eq('sold')
      end
    end

    context 'チケットが仮押さえされているとき' do
      before do
        cart = Cart.new(cart_user)
        cart.replace_tickets([{ ticket_id: cart_ticket.id, option_id: nil }], nil, nil)
      end

      let(:cart_ticket) { seat_area_a.tickets.first }

      context '別のユーザーが仮押さえしている場合' do
        let(:cart_user) { create(:user) }

        it 'チケットのステータスではなくtemporary_holdが返ること' do
          get_area_tickets
          json = JSON.parse(response.body)

          expect(cart_ticket.status).to eq('available')
          expect(json['tickets'].find { |t| t['id'] == cart_ticket.id }['status']).to eq('temporary_hold')
        end
      end

      context 'ユーザー自身が仮押さえしている場合' do
        let(:cart_user) { sales_logged_in_user }

        it 'チケットのステータスが返ること' do
          get_area_tickets
          json = JSON.parse(response.body)

          expect(json['tickets'].find { |t| t['id'] == cart_ticket.id }['status']).to eq(cart_ticket.status)
        end
      end
    end
  end
end

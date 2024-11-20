# frozen_string_literal: true

# == Schema Information
#
# Table name: tickets
#
#  id                         :bigint           not null, primary key
#  admission_disabled_at      :datetime
#  row                        :string(255)
#  sales_type                 :integer          default("single"), not null
#  seat_number                :integer          not null
#  status                     :integer          default("available"), not null
#  transfer_uuid              :string(255)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  current_ticket_reserve_id  :bigint
#  master_seat_unit_id        :bigint
#  purchase_ticket_reserve_id :bigint
#  qr_ticket_id               :string(255)
#  seat_area_id               :bigint           not null
#  seat_type_id               :bigint           not null
#  user_id                    :bigint
#
# Indexes
#
#  fk_rails_a75cd836ef                   (purchase_ticket_reserve_id)
#  fk_rails_aa4180ad50                   (current_ticket_reserve_id)
#  index_tickets_on_master_seat_unit_id  (master_seat_unit_id)
#  index_tickets_on_seat_area_id         (seat_area_id)
#  index_tickets_on_seat_type_id         (seat_type_id)
#  index_tickets_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (current_ticket_reserve_id => ticket_reserves.id)
#  fk_rails_...  (master_seat_unit_id => master_seat_units.id)
#  fk_rails_...  (purchase_ticket_reserve_id => ticket_reserves.id)
#  fk_rails_...  (seat_area_id => seat_areas.id)
#  fk_rails_...  (seat_type_id => seat_types.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Ticket, type: :model do
  let(:ticket) { create(:ticket) }

  describe '#before_enter?' do
    context 'チケットが有効期限切れの場合' do
      let(:ticket) { create(:ticket, seat_type: seat_type) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :after_closing) }

      it 'falseであること' do
        expect(ticket).not_to be_before_enter
      end
    end

    context 'チケットが有効期限内の場合' do
      let(:ticket) { create(:ticket, seat_type: seat_type) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      it 'trueであること' do
        expect(ticket).to be_before_enter
      end

      context 'ticket_logがある場合' do
        it 'ticket_logの最後のステータスがbefore_enterの場合はtrueであること' do
          create(:ticket_log, ticket: ticket, result_status: :before_enter)
          expect(ticket).to be_before_enter
        end

        it 'ticket_logの最後のステータスがbefore_enterの以外の場合はfalseであること' do
          TicketLog.statuses.each_key do |key|
            next if key == 'before_enter'

            create(:ticket_log, ticket: ticket, result_status: key)
            expect(ticket).not_to be_before_enter
          end
        end
      end
    end
  end

  describe '#expire?' do
    context 'チケットが有効期限切れの場合' do
      let(:ticket) { create(:ticket, seat_type: seat_type) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :after_closing) }

      it 'trueであること' do
        expect(ticket.expired?).to be true
      end
    end

    context 'チケットが有効期限内の場合' do
      let(:ticket) { create(:ticket, seat_type: seat_type) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      it 'trueであること' do
        expect(ticket.expired?).to be false
      end
    end
  end

  describe '#stop_selling!' do
    subject(:stop_selling!) { ticket.stop_selling! }

    let(:ticket) { create(:ticket, status: status, seat_type: seat_type) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_sale) { create(:seat_sale, seat_sale_term) }
    let(:seat_sale_term) { :in_admission_term }

    context 'Ticketのステータスが販売可能である場合' do
      let(:status) { :available }

      it 'ステータスが仮押さえに変更されること' do
        expect { stop_selling! }.to change(ticket, :status).from('available').to('not_for_sale')
      end
    end

    context 'Ticketのステータスが販売済みである場合' do
      let(:status) { :sold }

      it 'エラーが発生すること' do
        expect { stop_selling! }.to raise_error(ApiBadRequestError, I18n.t('custom_errors.ticket.not_available'))
      end
    end

    context 'Ticketのステータスが販売処理中である場合' do
      let(:status) { :temporary_hold }

      it 'エラーが発生すること' do
        expect { stop_selling! }.to raise_error(ApiBadRequestError, I18n.t('custom_errors.ticket.not_available'))
      end
    end

    context 'Ticketのステータスが仮押さえ済みである場合' do
      let(:status) { :not_for_sale }

      it 'エラーが発生すること' do
        expect { stop_selling! }.to raise_error(ApiBadRequestError, I18n.t('custom_errors.ticket.not_available'))
      end
    end

    context 'Ticketが有効期限切れである場合' do
      let(:status) { :available }
      let(:seat_sale_term) { :after_closing }

      it 'エラーが発生すること' do
        expect { stop_selling! }.to raise_error(ApiBadRequestError, I18n.t('seat_sales.over_close_at'))
      end
    end

    context 'ユーザーが所有するTicketである場合' do
      let(:status) { :available }
      let(:user) { create(:user) }

      before do
        ticket.update(user: user)
      end

      it '「チケットは購入済み、または決済処理中のため変更できません」のエラーが発生すること' do
        expect { stop_selling! }.to raise_error(ApiBadRequestError, I18n.t('custom_errors.ticket.sold_or_temporary_hold'))
      end
    end
  end

  describe 'release_from_stop_selling!' do
    subject(:release_from_stop_selling!) { ticket.release_from_stop_selling! }

    let(:ticket) { create(:ticket, status: status, seat_type: seat_type, transfer_uuid: transfer_uuid) }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_sale) { create(:seat_sale, seat_sale_term) }
    let(:seat_sale_term) { :in_admission_term }
    let(:transfer_uuid) { nil }

    context 'Ticketのステータスが仮押さえ済みである場合' do
      let(:status) { :not_for_sale }

      it 'ステータスが販売可能に変更されること' do
        expect { release_from_stop_selling! }.to change(ticket, :status).from('not_for_sale').to('available')
      end
    end

    context 'Ticketのステータスが販売済みである場合' do
      let(:status) { :sold }

      it 'エラーが発生すること' do
        expect { release_from_stop_selling! }.to raise_error(ApiBadRequestError, I18n.t('custom_errors.ticket.not_stop_selling'))
      end
    end

    context 'Ticketのステータスが販売処理中である場合' do
      let(:status) { :temporary_hold }

      it 'エラーが発生すること' do
        expect { release_from_stop_selling! }.to raise_error(ApiBadRequestError, I18n.t('custom_errors.ticket.not_stop_selling'))
      end
    end

    context 'Ticketのステータスが販売可能である場合' do
      let(:status) { :available }

      it 'エラーが発生すること' do
        expect { release_from_stop_selling! }.to raise_error(ApiBadRequestError, I18n.t('custom_errors.ticket.not_stop_selling'))
      end
    end

    context 'Ticketが有効期限切れである場合' do
      let(:status) { :not_for_sale }
      let(:seat_sale_term) { :after_closing }

      it 'エラーが発生すること' do
        expect { release_from_stop_selling! }.to raise_error(ApiBadRequestError, I18n.t('seat_sales.over_close_at'))
      end
    end

    context 'Ticketが譲渡中である場合' do
      let(:status) { :not_for_sale }
      let(:transfer_uuid) { 'test' }

      it 'エラーが発生すること' do
        expect { release_from_stop_selling! }.to raise_error(ApiBadRequestError, I18n.t('custom_errors.ticket.transferring'))
      end
    end
  end

  describe '#sold_ticket_uuid_generate!' do
    subject(:sold_ticket_uuid_generate!) { ticket.sold_ticket_uuid_generate! }

    context 'ticketのステータスがavailableの場合' do
      let(:ticket) { create(:ticket, seat_type: seat_type, status: :available) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      it 'エラーが発生すること' do
        expect { sold_ticket_uuid_generate! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_sold_ticket'))
      end
    end

    context 'ticketのステータスがsoldの場合' do
      let(:ticket) { create(:ticket, :sold, seat_type: seat_type) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      it 'transfer_uuidが埋められること' do
        expect { sold_ticket_uuid_generate! }.to change { ticket.transfer_uuid.present? }.from(false).to(true)
      end

      it 'qr_ticket_idがnilになること' do
        ticket.qr_ticket_id_generate!
        expect { sold_ticket_uuid_generate! }.to change { ticket.qr_ticket_id.present? }.from(true).to(false)
      end
    end

    context 'ticketのステータスがnot_for_saleの場合' do
      let(:ticket) { create(:ticket, :not_for_sale, seat_type: seat_type) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      it 'エラーが発生すること' do
        expect { sold_ticket_uuid_generate! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_sold_ticket'))
      end
    end

    context '入場締切時間を過ぎている場合' do
      let(:ticket) { create(:ticket, :not_for_sale, seat_type: seat_type) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :after_closing) }

      it 'エラーが発生すること' do
        expect { sold_ticket_uuid_generate! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.ticket_has_expired'))
      end
    end

    context 'ticketが譲渡済みの場合' do
      let(:ticket) { create(:ticket, :sold, seat_type: seat_type, transfer_uuid: 'transferred') }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      it 'エラーが発生すること' do
        expect { sold_ticket_uuid_generate! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.transferred'))
      end
    end

    context 'すでに入場している場合' do
      let(:ticket) { create(:ticket, :sold, seat_type: seat_type) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      before do
        create(:ticket_log, ticket: ticket, result_status: :entered)
      end

      it 'エラーが発生すること' do
        expect { sold_ticket_uuid_generate! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.ticket_has_admission'))
      end
    end

    context '未入場の場合' do
      let(:ticket) { create(:ticket, :sold, seat_type: seat_type) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      before do
        create(:ticket_log, ticket: ticket, result_status: :before_enter)
      end

      it 'transfer_uuidが埋められること' do
        expect { sold_ticket_uuid_generate! }.to change { ticket.transfer_uuid.present? }.from(false).to(true)
      end
    end
  end

  describe '#not_for_sale_ticket_uuid_generate!' do
    subject(:not_for_sale_ticket_uuid_generate!) { ticket.not_for_sale_ticket_uuid_generate! }

    context 'ticketのステータスがavailableの場合' do
      let(:ticket) { create(:ticket, seat_type: seat_type, status: :available) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      it 'エラーが発生すること' do
        expect { not_for_sale_ticket_uuid_generate! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_stop_selling'))
      end
    end

    context 'ticketのステータスがsoldの場合' do
      let(:ticket) { create(:ticket, :sold, seat_type: seat_type) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      it 'エラーが発生すること' do
        expect { not_for_sale_ticket_uuid_generate! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_stop_selling'))
      end
    end

    context 'ticketのステータスがnot_for_saleの場合' do
      let(:ticket) { create(:ticket, :not_for_sale, seat_type: seat_type) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      it 'transfer_uuidが埋められること' do
        expect { not_for_sale_ticket_uuid_generate! }.to change { ticket.transfer_uuid.present? }.from(false).to(true)
      end

      it 'qr_ticket_idがnilになること' do
        ticket.qr_ticket_id_generate!
        expect { not_for_sale_ticket_uuid_generate! }.to change { ticket.qr_ticket_id.present? }.from(true).to(false)
      end
    end

    context '入場締切時間を過ぎている場合' do
      let(:ticket) { create(:ticket, :not_for_sale, seat_type: seat_type) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :after_closing) }

      it 'エラーが発生すること' do
        expect { not_for_sale_ticket_uuid_generate! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.ticket_has_expired'))
      end
    end

    context 'ticketが譲渡済みの場合' do
      let(:ticket) { create(:ticket, :not_for_sale, seat_type: seat_type, transfer_uuid: 'transferred') }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      it 'エラーが発生すること' do
        expect { not_for_sale_ticket_uuid_generate! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.transferred'))
      end
    end
  end

  describe 'receive_transfer_ticket!' do
    subject(:receive_transfer_ticket!) { ticket.receive_transfer_ticket!(receive_user) }

    let(:receive_user) { create(:user) }
    let(:ticket_owner) { create(:user) }

    let(:ticket) { create(:ticket, user: ticket_owner, status: status, seat_type: seat_type) }
    let(:status) { :sold }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_sale) { create(:seat_sale, seat_sale_term) }
    let(:seat_sale_term) { :in_admission_term }
    let(:seat_type_option) { create(:seat_type_option, seat_type: seat_type) }

    let(:ticket_owner_order) { create(:order, user: ticket_owner, seat_sale: seat_sale) }
    let(:ticket_owner_ticket_reserve) { create(:ticket_reserve, ticket: ticket, seat_type_option: seat_type_option, order: ticket_owner_order) }

    before do
      ticket_owner_ticket_reserve.ticket.sold_ticket_uuid_generate!
      ticket.update(current_ticket_reserve_id: ticket_owner_ticket_reserve.id)
      create(:payment, order: ticket_owner_order, payment_progress: :captured)
    end

    it '各関連レコードが更新されること' do
      receive_transfer_ticket!

      ticket.reload
      ticket_owner_ticket_reserve.reload
      ticket_reserve = ticket.ticket_reserves.last
      order = receive_user.orders.last

      # 譲渡ログの更新
      expect(ticket_owner_ticket_reserve.transfer_at.present?).to be true
      expect(ticket_owner_ticket_reserve.transfer_to_user_id).to eq(receive_user.id)
      expect(ticket_owner_ticket_reserve.next_ticket_reserve_id).to eq(ticket_reserve.id)

      # チケットの紐づき更新
      expect(ticket.user_id).to eq(receive_user.id)
      expect(ticket.transfer_uuid.present?).to be false
      expect(ticket.qr_ticket_id.present?).to be true
      expect(ticket.current_ticket_reserve_id).to eq(ticket_reserve.id)

      # オーダー作成
      expect(order.order_type).to eq('transfer')
      expect(order.total_price).to eq(0)
      expect(order.seat_sale_id).to eq(seat_sale.id)

      # チケット予約作成
      expect(ticket_reserve.order_id).to eq(order.id)
      expect(ticket_reserve.ticket_id).to eq(ticket.id)
      expect(ticket_reserve.transfer_from_user_id).to eq(ticket_owner.id)
      expect(ticket_reserve.seat_type_option_id).to eq(ticket_owner_ticket_reserve.seat_type_option_id)
      expect(ticket_reserve.previous_ticket_reserve_id).to eq(ticket_owner_ticket_reserve.id)
    end

    context '譲渡ユーザーと受け取りユーザーが一致している場合' do
      let(:receive_user) { ticket_owner }

      it 'エラーが発生すること' do
        expect { receive_transfer_ticket! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.to_yourself'))
      end
    end

    context 'チケットのステータスが販売可能の場合' do
      before do
        ticket.available!
      end

      it 'エラーが発生すること' do
        expect { receive_transfer_ticket! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_sold_ticket'))
      end
    end

    context 'チケットのステータスが仮押さえ済みの場合' do
      before do
        ticket.not_for_sale!
      end

      it 'エラーが発生すること' do
        expect { receive_transfer_ticket! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_sold_ticket'))
      end
    end

    context 'チケットのステータスが決済処理中の場合' do
      before do
        ticket.temporary_hold!
      end

      it 'エラーが発生すること' do
        expect { receive_transfer_ticket! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_sold_ticket'))
      end
    end

    context 'チケットが有効期限切れの場合' do
      before do
        seat_sale.update(admission_available_at: Time.zone.now - 1.day, admission_close_at: Time.zone.now - 12.hours)
      end

      it 'エラーが発生すること' do
        expect { receive_transfer_ticket! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.ticket_has_expired'))
      end
    end

    context '管理画面から譲渡の場合' do
      let(:ticket_owner_order) { create(:order, user: ticket_owner, seat_sale: seat_sale, order_type: :admin_transfer) }

      it '各関連レコードが更新されること' do
        receive_transfer_ticket!

        ticket.reload
        ticket_owner_ticket_reserve.reload
        ticket_reserve = ticket.ticket_reserves.last
        order = receive_user.orders.last

        # 譲渡ログの更新
        expect(ticket_owner_ticket_reserve.transfer_at.present?).to be true
        expect(ticket_owner_ticket_reserve.transfer_to_user_id).to eq(receive_user.id)
        expect(ticket_owner_ticket_reserve.next_ticket_reserve_id).to eq(ticket_reserve.id)

        # チケットの紐づき更新
        expect(ticket.user_id).to eq(receive_user.id)
        expect(ticket.transfer_uuid.present?).to be false
        expect(ticket.qr_ticket_id.present?).to be true
        expect(ticket.current_ticket_reserve_id).to eq(ticket_reserve.id)

        # オーダー作成
        expect(order.order_type).to eq('transfer')
        expect(order.total_price).to eq(0)
        expect(order.seat_sale_id).to eq(seat_sale.id)

        # チケット予約作成
        expect(ticket_reserve.order_id).to eq(order.id)
        expect(ticket_reserve.ticket_id).to eq(ticket.id)
        expect(ticket_reserve.transfer_from_user_id).to eq(ticket_owner.id)
        expect(ticket_reserve.seat_type_option_id).to eq(ticket_owner_ticket_reserve.seat_type_option_id)
        expect(ticket_reserve.previous_ticket_reserve_id).to eq(ticket_owner_ticket_reserve.id)
      end
    end

    context 'TicketReserveが３つある場合（requesting_paymentが２つ、capturedが１つあるケース）' do
      before do
        create(:ticket_reserve, order: order1, ticket: ticket, seat_type_option: nil)
        create(:ticket_reserve, order: order2, ticket: ticket, seat_type_option: nil)
        create(:payment, order: order1, payment_progress: :requesting_payment)
        create(:payment, order: order2, payment_progress: :requesting_payment)
        create(:payment, order: ticket_owner_order, payment_progress: :captured)
      end

      let(:order1) { create(:order, order_type: :purchase, user: ticket_owner, seat_sale: seat_sale) }
      let(:order2) { create(:order, order_type: :purchase, user: ticket_owner, seat_sale: seat_sale) }

      it '各関連レコードが更新されること' do
        receive_transfer_ticket!

        ticket.reload
        ticket_owner_ticket_reserve.reload
        ticket_reserve = ticket.ticket_reserves.last
        order = receive_user.orders.last

        # 譲渡ログの更新
        expect(ticket_owner_ticket_reserve.transfer_at.present?).to be true
        expect(ticket_owner_ticket_reserve.transfer_to_user_id).to eq(receive_user.id)
        expect(ticket_owner_ticket_reserve.next_ticket_reserve_id).to eq(ticket_reserve.id)

        # チケットの紐づき更新
        expect(ticket.user_id).to eq(receive_user.id)
        expect(ticket.transfer_uuid.present?).to be false
        expect(ticket.qr_ticket_id.present?).to be true
        expect(ticket.current_ticket_reserve_id).to eq(ticket_reserve.id)

        # オーダー作成
        expect(order.order_type).to eq('transfer')
        expect(order.total_price).to eq(0)
        expect(order.seat_sale_id).to eq(seat_sale.id)

        # チケット予約作成
        expect(ticket_reserve.order_id).to eq(order.id)
        expect(ticket_reserve.ticket_id).to eq(ticket.id)
        expect(ticket_reserve.transfer_from_user_id).to eq(ticket_owner.id)
        expect(ticket_reserve.seat_type_option_id).to eq(ticket_owner_ticket_reserve.seat_type_option_id)
        expect(ticket_reserve.previous_ticket_reserve_id).to eq(ticket_owner_ticket_reserve.id)
      end
    end

    context 'TicketReserveにすでに譲渡がある場合' do
      before do
        create(:ticket_reserve, order: order1, ticket: ticket, seat_type_option: nil)
        create(:ticket_reserve, order: order2, ticket: ticket, seat_type_option: seat_type_option, transfer_at: Time.zone.now)
        create(:payment, order: order1, payment_progress: :requesting_payment)
        create(:payment, order: order2, payment_progress: :captured)
        create(:payment, order: ticket_owner_order, payment_progress: :captured)
      end

      let(:user2) { create(:user, qr_user_id: 'test2') }
      let(:ticket_owner_ticket_reserve) { create(:ticket_reserve, order: ticket_owner_order, ticket: ticket, seat_type_option: nil) }
      let(:order1) { create(:order, order_type: :purchase, user: user2, seat_sale: seat_sale) }
      let(:order2) { create(:order, order_type: :purchase, user: user2, seat_sale: seat_sale) }
      let(:ticket_owner_order) { create(:order, order_type: :transfer, user: ticket_owner, seat_sale: seat_sale) }

      it '各関連レコードが更新されること' do
        receive_transfer_ticket!

        ticket.reload
        ticket_owner_ticket_reserve.reload
        ticket_reserve = ticket.ticket_reserves.last
        order = receive_user.orders.last

        # 譲渡ログの更新
        expect(ticket_owner_ticket_reserve.transfer_at.present?).to be true
        expect(ticket_owner_ticket_reserve.transfer_to_user_id).to eq(receive_user.id)
        expect(ticket_owner_ticket_reserve.next_ticket_reserve_id).to eq(ticket_reserve.id)

        # チケットの紐づき更新
        expect(ticket.user_id).to eq(receive_user.id)
        expect(ticket.transfer_uuid.present?).to be false
        expect(ticket.qr_ticket_id.present?).to be true
        expect(ticket.current_ticket_reserve_id).to eq(ticket_reserve.id)

        # オーダー作成
        expect(order.order_type).to eq('transfer')
        expect(order.total_price).to eq(0)
        expect(order.seat_sale_id).to eq(seat_sale.id)
        expect(order.user_id).to eq(receive_user.id)

        # チケット予約作成
        expect(ticket_reserve.order_id).to eq(order.id)
        expect(ticket_reserve.ticket_id).to eq(ticket.id)
        expect(ticket_reserve.transfer_from_user_id).to eq(ticket_owner.id)
        expect(ticket_reserve.seat_type_option_id).to eq(ticket_owner_ticket_reserve.seat_type_option_id)
        expect(ticket_reserve.previous_ticket_reserve_id).to eq(ticket_owner_ticket_reserve.id)
      end
    end
  end

  describe 'receive_admin_transfer_ticket!' do
    subject(:receive_admin_transfer_ticket!) { ticket.receive_admin_transfer_ticket!(receive_user) }

    let(:receive_user) { create(:user) }

    let(:ticket) do
      create(
        :ticket,
        status: status,
        seat_type: seat_type,
        sales_type: sales_type,
        master_seat_unit: master_seat_unit
      )
    end
    let(:status) { :not_for_sale }
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_sale) { create(:seat_sale, seat_sale_admission_term, seat_sale_sale_term) }
    let(:seat_sale_sale_term) { :available }
    let(:seat_sale_admission_term) { :in_admission_term }
    let(:sales_type) { :single }
    let(:master_seat_unit) { nil }

    before do
      ticket.not_for_sale_ticket_uuid_generate!
    end

    it '各関連レコードが更新されること' do
      receive_admin_transfer_ticket!

      order = receive_user.orders.last

      # チケットの紐づき更新
      ticket.reload
      ticket_reserve = ticket.ticket_reserves.last
      expect(ticket.user_id).to eq(receive_user.id)
      expect(ticket.transfer_uuid.present?).to be false
      expect(ticket.qr_ticket_id.present?).to be true
      expect(ticket.current_ticket_reserve_id).to eq(ticket_reserve.id)

      # オーダー作成
      expect(order.order_type).to eq('admin_transfer')
      expect(order.total_price).to eq(0)
      expect(order.seat_sale_id).to eq(seat_sale.id)

      # チケット予約作成
      expect(ticket_reserve.order_id).to eq(order.id)
      expect(ticket_reserve.ticket_id).to eq(ticket.id)

      # 管理譲渡の場合はnil
      expect(ticket_reserve.transfer_from_user_id).to eq(nil)
      expect(ticket_reserve.seat_type_option_id).to eq(nil)
    end

    context '単体座席の場合' do
      it '座席が一つだけ紐づくこと' do
        receive_admin_transfer_ticket!

        order = receive_user.orders.last
        expect(order.ticket_reserves.count).to eq(1)
      end
    end

    context 'Unit座席の場合' do
      let(:sales_type) { :unit }
      let(:master_seat_unit) { create(:master_seat_unit) }

      before do
        create_list(
          :ticket,
          3,
          status: status,
          seat_type: seat_type,
          sales_type: sales_type,
          master_seat_unit: master_seat_unit
        )
      end

      it '関連するUnit席が全て紐づくこと' do
        receive_admin_transfer_ticket!

        order = receive_user.orders.last
        expect(order.ticket_reserves.count).to eq(4)
        expect(order.tickets.all? { |ticket| ticket.user_id == receive_user.id }).to be true
      end

      it '関連するUnit席が全てticket_reserveを持つこと' do
        receive_admin_transfer_ticket!

        tickets = receive_user.orders.last.tickets
        tickets.each { |ticket| expect(ticket.ticket_reserves).to be_present }
      end
    end

    context 'チケットのステータスが販売可能の場合' do
      before do
        ticket.available!
      end

      it 'エラーが発生すること' do
        expect { receive_admin_transfer_ticket! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_stop_selling'))
      end
    end

    context 'チケットのステータスが販売済みの場合' do
      before do
        ticket.sold!
      end

      it 'エラーが発生すること' do
        expect { receive_admin_transfer_ticket! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_stop_selling'))
      end
    end

    context 'チケットのステータスが決済処理中の場合' do
      before do
        ticket.temporary_hold!
      end

      it 'エラーが発生すること' do
        expect { receive_admin_transfer_ticket! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_stop_selling'))
      end
    end

    context 'チケットが有効期限切れの場合' do
      before do
        seat_sale.update(admission_available_at: Time.zone.now - 1.day, admission_close_at: Time.zone.now - 12.hours)
      end

      it 'エラーが発生すること' do
        expect { receive_admin_transfer_ticket! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.ticket_has_expired'))
      end
    end

    context 'チケット入場終了時間を過ぎておらず、チケット販売終了時間を過ぎている場合' do
      before do
        seat_sale.update(sales_end_at: Time.zone.yesterday, admission_close_at: Time.zone.tomorrow)
      end

      it '各関連レコードが更新されること' do
        receive_admin_transfer_ticket!
        order = receive_user.orders.last

        # チケットの紐づき更新
        ticket.reload
        ticket_reserve = ticket.ticket_reserves.last
        expect(ticket.user_id).to eq(receive_user.id)
        expect(ticket.transfer_uuid.present?).to be false
        expect(ticket.qr_ticket_id.present?).to be true
        expect(ticket.current_ticket_reserve_id).to eq(ticket_reserve.id)

        # オーダー作成
        expect(order.order_type).to eq('admin_transfer')
        expect(order.total_price).to eq(0)
        expect(order.seat_sale_id).to eq(seat_sale.id)

        # チケット予約作成
        expect(ticket_reserve.order_id).to eq(order.id)
        expect(ticket_reserve.ticket_id).to eq(ticket.id)

        # 管理譲渡の場合はnil
        expect(ticket_reserve.transfer_from_user_id).to eq(nil)
        expect(ticket_reserve.seat_type_option_id).to eq(nil)
      end
    end
  end

  describe 'cancel_transfer!' do
    subject(:cancel_transfer!) { ticket.cancel_transfer! }

    let(:ticket) { create(:ticket, seat_type: seat_type, status: status, transfer_uuid: transfer_uuid) }
    let(:status) { :sold }
    let(:seat_type) { create(:seat_type) }
    let(:transfer_uuid) { 'test' }

    context 'チケットが譲渡中の場合' do
      it '譲渡idが空になること' do
        expect { cancel_transfer! }.to change { ticket.transfer_uuid.present? }.from(true).to(false)
      end

      it 'qr_ticket_id に再び値が入ること' do
        expect { cancel_transfer! }.to change { ticket.qr_ticket_id.present? }.from(false).to(true)
      end
    end

    context 'チケットのステータスが販売可能の場合' do
      let(:status) { :available }

      it 'エラーが発生すること' do
        expect { cancel_transfer! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_sold_ticket'))
      end
    end

    context 'チケットのステータスが仮押さえ済みの場合' do
      let(:status) { :not_for_sale }

      it 'エラーが発生すること' do
        expect { cancel_transfer! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_sold_ticket'))
      end
    end

    context 'チケットのステータスが決済中の場合' do
      let(:status) { :temporary_hold }

      it 'エラーが発生すること' do
        expect { cancel_transfer! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_sold_ticket'))
      end
    end

    context '譲渡idが空の場合' do
      let(:transfer_uuid) { nil }

      it 'エラーが発生すること' do
        expect { cancel_transfer! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_transferred'))
      end
    end
  end

  describe 'cancel_admin_transfer!' do
    subject(:cancel_admin_transfer!) { ticket.cancel_admin_transfer! }

    let(:ticket) { create(:ticket, seat_type: seat_type, status: status, transfer_uuid: transfer_uuid) }
    let(:status) { :not_for_sale }
    let(:seat_type) { create(:seat_type) }
    let(:transfer_uuid) { 'test' }

    context 'チケットが譲渡中の場合' do
      it '譲渡idが空になること' do
        expect { cancel_admin_transfer! }.to change { ticket.transfer_uuid.present? }.from(true).to(false)
      end
    end

    context 'チケットのステータスが販売可能の場合' do
      let(:status) { :available }

      it 'エラーが発生すること' do
        expect { cancel_admin_transfer! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_stop_selling'))
      end
    end

    context 'チケットのステータスが販売済みの場合' do
      let(:status) { :sold }

      it 'エラーが発生すること' do
        expect { cancel_admin_transfer! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_stop_selling'))
      end
    end

    context 'チケットのステータスが決済中の場合' do
      let(:status) { :temporary_hold }

      it 'エラーが発生すること' do
        expect { cancel_admin_transfer! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_stop_selling'))
      end
    end

    context '譲渡idが空の場合' do
      let(:transfer_uuid) { nil }

      it 'エラーが発生すること' do
        expect { cancel_admin_transfer! }.to raise_error(TransferTicketError, I18n.t('custom_errors.transfer.not_transferred'))
      end
    end
  end

  describe '#try_reserve' do
    let(:user) { create(:user) }
    let(:ticket) { create(:ticket) }

    before do
      ticket.try_reserve(user.id)
    end

    it 'temporary_owner_idと確保したuserのidが一致すること' do
      expect(ticket.temporary_owner_id.value).to eq(user.id)
    end
  end

  describe '#count_unit_tickets' do
    let!(:seat_sale) { create(:seat_sale) }
    let!(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let!(:master_seat_unit) { create(:master_seat_unit, seat_type: 0) }
    let!(:master_seat_unit_2) { create(:master_seat_unit, seat_type: 0) }

    it '他のBox席に同じ席種が設定されていた場合' do
      create(:ticket, seat_type: seat_type, sales_type: 1, master_seat_unit: master_seat_unit)
      create(:ticket, seat_type: seat_type, sales_type: 1, master_seat_unit: master_seat_unit_2)
      expect(seat_type.tickets.count).to be(2)

      unit_tickets_size = seat_type.tickets.first.master_seat_unit.tickets.joins(:seat_type).where('seat_types.seat_sale_id = ?', seat_type.seat_sale_id).distinct.count
      expect(unit_tickets_size).to be(1)
    end
  end

  describe '#ticket_release' do
    let(:user) { create(:user) }
    let(:ticket) { create(:ticket) }

    before do
      ticket.try_reserve(user.id)
    end

    it 'temporary_owner_idが空に変更されること' do
      expect { ticket.ticket_release(user.id) }.to change { ticket.temporary_owner_id.value }.from(user.id).to(nil)
    end
  end

  describe '#temporary_owner?' do
    let(:user) { create(:user) }
    let(:ticket) { create(:ticket) }
    let(:other_user) { create(:user) }

    before do
      ticket.try_reserve(user.id)
    end

    it '確保したユーザーならばtrueであること' do
      expect(ticket.temporary_owner?(user.id)).to be(true)
    end

    it '確保したユーザー以外ならばfalseであること' do
      expect(ticket.temporary_owner?(other_user.id)).to be(false)
    end

    context '所有権の延長' do
      it '確保期限が延長されていること' do
        old_ttl = ticket.temporary_owner_id.ttl
        ticket.temporary_owner?(user.id, 60.minutes)
        expect(ticket.temporary_owner_id.ttl).to be >= old_ttl
      end
    end
  end

  describe '#temporary_reserved?' do
    let(:user) { create(:user) }
    let(:ticket) { create(:ticket) }

    context '既にユーザーがチケットを確保しているとき' do
      before do
        ticket.try_reserve(user.id)
      end

      it 'trueであること' do
        expect(ticket.temporary_reserved?).to be(true)
      end
    end

    context 'まだチケットを確保するユーザーがいない時' do
      it 'falseであること' do
        expect(ticket.temporary_reserved?).to be(false)
      end
    end
  end

  describe '#temporary_reservable?' do
    let(:user) { create(:user) }
    let(:ticket) { create(:ticket) }
    let(:other_user) { create(:user) }

    context 'まだチケットを確保するユーザーがいない時' do
      it 'trueであること' do
        expect(ticket.temporary_reservable?(other_user.id)).to be(true)
      end
    end

    context '既にユーザーがチケットを確保しているとき' do
      before do
        ticket.try_reserve(user.id)
      end

      it 'falseであること' do
        expect(ticket.temporary_reservable?(other_user.id)).to be(false)
      end
    end

    context 'チケットを確保しているのが自身であるとき' do
      before do
        ticket.try_reserve(user.id)
      end

      it 'trueであること' do
        expect(ticket.temporary_reservable?(user.id)).to be(true)
      end
    end
  end

  describe '#qr_ticket_id_generate!' do
    let(:ticket) { create(:ticket) }

    it 'trueであること' do
      expect(ticket.qr_ticket_id_generate!).to be(true)
    end

    it 'ticket.qr_ticket_idに値が入っていること' do
      expect { ticket.qr_ticket_id_generate! }.to change { ticket.qr_ticket_id.present? }.from(false).to(true)
    end
  end

  describe '#correct_user?(user)' do
    let(:ticket) { create(:ticket) }
    let(:user) { create(:user) }

    it 'userがnilの場合falseであること' do
      expect(ticket).not_to be_correct_user(nil)
    end

    it 'userが対象のチケットを保持していない場合falseであること' do
      expect(ticket).not_to be_correct_user(user)
    end

    it 'userが対象のチケットを保持している場合trueであること' do
      ticket.update(user_id: user.id)
      expect(ticket).to be_correct_user(user)
    end

    it 'userが対象のチケットを保持していても、ticketのtransfer_uuidが入っている場合falseであること' do
      ticket.update(user_id: user.id, transfer_uuid: SecureRandom.urlsafe_base64(32))
      expect(ticket).not_to be_correct_user(user)
    end
  end

  describe 'validationの確認' do
    let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
    let(:seat_sale) { create(:seat_sale, :in_admission_term) }
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }

    it 'seat_numberがなければerrorになること' do
      ticket = described_class.new(row: 'A', seat_type: seat_type, seat_area: seat_area)
      expect(ticket.valid?).to eq false
    end

    it 'seat_area_idがなければerrorになること' do
      ticket = described_class.new(row: 'A', seat_number: 1, seat_type: seat_type)
      expect(ticket.valid?).to eq false
    end

    it 'seat_type_idがなければerrorになること' do
      ticket = described_class.new(row: 'A', seat_number: 1, seat_area: seat_area)
      expect(ticket.valid?).to eq false
    end
  end

  describe 'coordinate_seat_numberの確認' do
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale, master_seat_area: master_seat_area) }
    let(:seat_sale) { create(:seat_sale, :in_admission_term) }
    let(:seat_type) { create(:seat_type) }
    let(:master_seat_area) { create(:master_seat_area, sub_code: sub_code) }
    let(:master_seat_unit) { create(:master_seat_unit, unit_name: unit_name, seat_type: master_seat_unit_seat_type) }
    let(:sub_code) { nil }
    let(:unit_name) { nil }
    let(:master_seat_unit_seat_type) { nil }

    context 'singleの場合' do
      context 'sub_codeがない(販売可能な座席)場合' do
        it '○列○番で返すこと' do
          ticket = described_class.new(row: 'A', seat_number: 98, seat_type: seat_type, seat_area: seat_area)
          expect(ticket.coordinate_seat_number).to eq('A列 98番')
        end

        context '列がない場合' do
          it '○番で返すこと' do
            ticket = described_class.new(row: nil, seat_number: 98, seat_type: seat_type, seat_area: seat_area)
            expect(ticket.coordinate_seat_number).to eq('98番')
          end
        end
      end

      context 'sub_codeがある(販売不可な座席)場合' do
        let(:sub_code) { 'Z' }

        it 'subcode + ○番で返すこと' do
          ticket = described_class.new(row: nil, seat_number: 98, seat_type: seat_type, seat_area: seat_area)
          expect(ticket.coordinate_seat_number).to eq('Z98番')
        end
      end
    end

    context 'unitでVIPの場合' do
      let(:master_seat_unit_seat_type) { 'vip' }
      let(:unit_name) { '1903' }

      it 'unit_nameを返すこと' do
        ticket = described_class.new(row: nil, seat_number: 1, seat_type: seat_type, seat_area: seat_area, sales_type: 1, master_seat_unit: master_seat_unit)
        expect(ticket.coordinate_seat_number).to eq('-')
      end
    end

    context 'boxの場合' do
      let(:master_seat_unit_seat_type) { 'box' }
      let(:unit_name) { '6' }

      it 'unit_nameを返すこと' do
        ticket = described_class.new(row: nil, seat_number: 1, seat_type: seat_type, seat_area: seat_area, sales_type: 1, master_seat_unit: master_seat_unit)
        expect(ticket.coordinate_seat_number).to eq('6番')
      end
    end
  end

  describe 'coordinate_seat_type_nameの確認' do
    let(:seat_area) { create(:seat_area, seat_sale: seat_sale, master_seat_area: master_seat_area) }
    let(:seat_sale) { create(:seat_sale, :in_admission_term) }
    let(:seat_type) { create(:seat_type) }
    let(:master_seat_area) { create(:master_seat_area, sub_code: sub_code, area_name: area_name, position: position) }
    let(:master_seat_unit) { create(:master_seat_unit, unit_name: unit_name, seat_type: master_seat_unit_seat_type) }
    let(:sub_code) { nil }
    let(:unit_name) { nil }
    let(:master_seat_unit_seat_type) { nil }
    let(:area_name) { 'A' }
    let(:position) { 'レギュラーシート' }

    context 'singleの場合' do
      context 'positionがある場合' do
        it 'エリア名 + " " + ポジションで返すこと' do
          ticket = described_class.new(row: 'A', seat_number: 98, seat_type: seat_type, seat_area: seat_area)
          expect(ticket.coordinate_seat_type_name).to eq('A レギュラーシート')
        end

        context 'ポジションがない（販売不可エリア）場合' do
          let(:sub_code) { 'Z' }
          let(:position) { nil }

          it 'エリア名で返すこと' do
            ticket = described_class.new(row: nil, seat_number: 98, seat_type: seat_type, seat_area: seat_area)
            expect(ticket.coordinate_seat_type_name).to eq('A')
          end
        end
      end
    end

    context 'boxの場合' do
      let(:master_seat_unit_seat_type) { 'box' }
      let(:unit_name) { '6' }
      let(:position) { 'BOXシート' }
      let(:area_name) { 'F' }

      it 'unit_nameを返すこと' do
        ticket = described_class.new(row: nil, seat_number: 1, seat_type: seat_type, seat_area: seat_area, sales_type: 1, master_seat_unit: master_seat_unit)
        expect(ticket.coordinate_seat_type_name).to eq('F BOXシート')
      end
    end

    context 'VIPの場合' do
      let(:master_seat_unit_seat_type) { 'vip' }
      let(:unit_name) { '1903' }
      let(:area_name) { 'VIPルーム' }

      it 'unit_nameを返すこと' do
        ticket = described_class.new(row: nil, seat_number: 1, seat_type: seat_type, seat_area: seat_area, sales_type: 1, master_seat_unit: master_seat_unit)
        expect(ticket.coordinate_seat_type_name).to eq('VIPルーム 1903')
      end
    end
  end

  describe '#purchase_order' do
    let(:ticket) { create(:ticket) }
    let(:purchase_order) do
      order = create(:order, order_type: :purchase)
      create(:payment, order: order, payment_progress: :captured)
      order
    end
    let(:refunded_order) do
      order = create(:order, order_type: :purchase)
      create(:payment, order: order, payment_progress: :refunded)
      order
    end
    let(:not_purchase_order) do
      order = create(:order, order_type: :purchase)
      create(:payment, order: order, payment_progress: :requesting_payment)
      order
    end
    let(:transfer_order) { create(:order, order_type: :transfer) }
    let(:admin_transfer_order) { create(:order, order_type: :admin_transfer) }
    let(:user) { create(:user) }

    context '購入されたチケットの場合' do
      before do
        tr = create(:ticket_reserve, ticket: ticket, order: purchase_order)
        ticket.update(purchase_ticket_reserve_id: tr.id)
      end

      it '想定しているorderが返ること' do
        expect(ticket.purchase_order.id).to eq(purchase_order.id)
      end

      it '購入後に譲渡された場合、想定しているorderが返ること' do
        ticket.ticket_reserves.first.update(transfer_at: Time.zone.now)
        # 譲渡のticket_reserve作成
        create(:ticket_reserve, ticket: ticket, order: transfer_order)
        expect(ticket.purchase_order.id).to eq(purchase_order.id)
      end
    end

    context '返金されたチケットの場合' do
      before do
        create(:ticket_reserve, ticket: ticket, order: refunded_order)
      end

      it 'nilが返ること' do
        expect(ticket.purchase_order).to be_nil
      end
    end

    context '購入できていないチケットの場合' do
      before do
        create(:ticket_reserve, ticket: ticket, order: not_purchase_order)
      end

      it 'nilが返ること' do
        expect(ticket.purchase_order).to be_nil
      end
    end

    context '管理画面譲渡チケットの場合' do
      before do
        create(:ticket_reserve, ticket: ticket, order: admin_transfer_order)
      end

      it 'nilが返ること' do
        expect(ticket.purchase_order).to be_nil
      end

      it '管理画面譲渡された後譲渡された場合、nilが返ること' do
        ticket.ticket_reserves.first.update(transfer_at: Time.zone.now)
        # 譲渡のticket_reserve作成
        create(:ticket_reserve, ticket: ticket, order: transfer_order)
        expect(ticket.purchase_order).to be_nil
      end
    end
  end
end

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
class Ticket < ApplicationRecord
  include Redis::Objects
  value :temporary_owner_id, marshal: true, expiration: Cart::CART_EXPIRATION

  belongs_to :user, optional: true
  belongs_to :seat_type
  belongs_to :seat_area
  belongs_to :master_seat_unit, optional: true
  belongs_to :purchase_ticket_reserve, optional: true, class_name: 'TicketReserve'
  belongs_to :current_ticket_reserve, optional: true, class_name: 'TicketReserve'
  has_many :ticket_reserves, dependent: :nullify
  has_many :ticket_logs, -> { order('created_at ASC') }, dependent: :nullify, inverse_of: :ticket
  has_many :visitor_profiles, dependent: :nullify
  has_many :orders, through: :ticket_reserves

  delegate :price, :master_seat_type, to: :seat_type
  delegate :master_seat_area, :seat_sale, to: :seat_area
  delegate :area_code, :area_name, :position, :sub_code, to: :master_seat_area
  delegate :name, to: :master_seat_type
  delegate :hold_daily_schedule, to: :seat_sale
  delegate :hold_daily, to: :hold_daily_schedule
  delegate :hold, to: :hold_daily

  enum status: {
    available: 0, # 空席・購入可能
    sold: 1, # 売り切れ
    not_for_sale: 2, # 販売停止
    temporary_hold: 3 # 決済処理中
  }

  enum sales_type: Rails.configuration.enum[:sales_type]

  # Validations -----------------------------------------------------------------------------------
  validates :seat_number, presence: true
  validates :seat_area_id, presence: true
  validates :seat_type_id, presence: true
  validates :sales_type, presence: true
  validates :status, presence: true

  def before_enter?
    !expired? && (ticket_logs.blank? || ticket_logs.last.result_status_before_enter?)
  end

  def expired?
    seat_type.seat_sale.admission_close?
  end

  def enter_available?
    seat_sale = seat_type.seat_sale
    seat_sale.admission_available? && !seat_sale.admission_close?
  end

  def correct_user?(user)
    return false if user.blank?

    ticket = user.tickets.find_by(id: id)
    return true if ticket.present? && ticket.transfer_uuid.nil?

    false
  end

  def stop_selling!
    raise ApiBadRequestError, I18n.t('custom_errors.ticket.sold_or_temporary_hold') if user_id
    raise ApiBadRequestError, I18n.t('custom_errors.ticket.not_available') unless available?
    raise ApiBadRequestError, I18n.t('seat_sales.over_close_at') if expired?

    not_for_sale!
  end

  def release_from_stop_selling!
    raise ApiBadRequestError, I18n.t('custom_errors.ticket.not_stop_selling') unless not_for_sale?
    raise ApiBadRequestError, I18n.t('seat_sales.over_close_at') if expired?
    raise ApiBadRequestError, I18n.t('custom_errors.ticket.transferring') if transfer_uuid.present?

    update!(status: :available)
  end

  def sold_ticket_uuid_generate!
    raise TransferTicketError, I18n.t('custom_errors.transfer.ticket_has_expired') if expired?
    raise TransferTicketError, I18n.t('custom_errors.transfer.not_sold_ticket') unless sold?
    raise TransferTicketError, I18n.t('custom_errors.transfer.transferred') unless transfer_uuid.nil?
    raise TransferTicketError, I18n.t('custom_errors.transfer.ticket_has_admission') unless before_enter?

    transfer_uuid_generate!
  end

  def not_for_sale_ticket_uuid_generate!
    raise TransferTicketError, I18n.t('custom_errors.transfer.ticket_has_expired') if expired?
    raise TransferTicketError, I18n.t('custom_errors.transfer.not_stop_selling') unless not_for_sale?
    raise TransferTicketError, I18n.t('custom_errors.transfer.transferred') unless transfer_uuid.nil?

    transfer_uuid_generate!
  end

  def receive_transfer_ticket!(receive_user)
    raise TransferTicketError, I18n.t('custom_errors.transfer.to_yourself') if receive_user == user
    raise TransferTicketError, I18n.t('custom_errors.transfer.not_sold_ticket') unless sold?
    raise TransferTicketError, I18n.t('custom_errors.transfer.ticket_has_expired') if expired?
    raise TransferTicketError, I18n.t('custom_errors.transfer.ticket_has_admission') unless before_enter?

    transfer_from_user_id = user_id
    transfer_ticket_reserve = current_ticket_reserve || ticket_reserves.not_transfer_ticket_reserve.filter_ticket_reserves&.last
    ActiveRecord::Base.transaction do
      # 申込の作成、譲渡の場合はtotal_priceは0で作成する
      order = Order.create!(user_id: receive_user.id,
                            order_at: Time.zone.now,
                            order_type: Order.order_types[:transfer], total_price: 0, seat_sale: transfer_ticket_reserve.order.seat_sale)
      # チケット予約の作成
      ticket_reserve = TicketReserve.create!(order_id: order.id, ticket_id: id, transfer_from_user_id: transfer_from_user_id, seat_type_option_id: transfer_ticket_reserve.seat_type_option_id, previous_ticket_reserve_id: transfer_ticket_reserve.id)
      # 譲渡元のticket_reservesの更新
      transfer_ticket_reserve.update!(transfer_at: Time.zone.now, transfer_to_user_id: receive_user.id, next_ticket_reserve_id: ticket_reserve.id)
      # チケットの紐付け更新, 譲渡URLを削除, 有効なticket_reserveのidを更新
      update!(user_id: receive_user.id, transfer_uuid: nil, qr_ticket_id: AdmissionUuid.generate_uuid, current_ticket_reserve_id: ticket_reserve.id)
    end
  end

  def receive_admin_transfer_ticket!(receive_user)
    raise TransferTicketError, I18n.t('custom_errors.transfer.not_stop_selling') unless not_for_sale?
    raise TransferTicketError, I18n.t('custom_errors.transfer.ticket_has_expired') if expired?

    seat_sale = seat_type.seat_sale
    raise TransferTicketError, I18n.t('custom_errors.orders.unapproved_sales') unless seat_sale.on_sale?

    target_tickets =
      if unit?
        master_seat_unit.tickets.where(seat_type: seat_type)
      else
        [self]
      end

    ActiveRecord::Base.transaction do
      # 申込の作成、譲渡の場合はtotal_priceは0で作成する
      order = Order.create!(user_id: receive_user.id, order_at: Time.zone.now, order_type: :admin_transfer, total_price: 0, seat_sale: seat_sale)

      target_tickets.each do |ticket|
        # チケット予約の作成
        ticket_reserve = TicketReserve.create!(order_id: order.id, ticket_id: ticket.id)
        # チケットの紐付け更新, 譲渡URLを削除, 有効なticket_reserveのidを更新
        ticket.update!(status: :sold, user_id: receive_user.id, transfer_uuid: nil, qr_ticket_id: AdmissionUuid.generate_uuid, current_ticket_reserve_id: ticket_reserve.id)
      end
    end
  end

  def cancel_transfer!
    raise TransferTicketError, I18n.t('custom_errors.transfer.not_sold_ticket') unless sold?
    raise TransferTicketError, I18n.t('custom_errors.transfer.not_transferred') if transfer_uuid.nil?

    update!(transfer_uuid: nil, qr_ticket_id: AdmissionUuid.generate_uuid)
  end

  def cancel_admin_transfer!
    raise TransferTicketError, I18n.t('custom_errors.transfer.not_stop_selling') unless not_for_sale?
    raise TransferTicketError, I18n.t('custom_errors.transfer.not_transferred') if transfer_uuid.nil?

    update!(transfer_uuid: nil)
  end

  def temporary_reserved?
    temporary_owner_id.value.present?
  end

  def temporary_owner?(user_id, extend_ttl = nil)
    ownership = temporary_owner_id.value == user_id
    extend_ownership_ttl(extend_ttl) if extend_ttl && ownership
    ownership
  end

  def temporary_reservable?(user_id)
    !temporary_reserved? || temporary_owner?(user_id)
  end

  def try_reserve(user_id)
    return false unless temporary_reservable?(user_id)

    redis = Redis.current
    # 既にロックが作成済みだった場合はfalse。作成できればtrue
    lock_author = redis.setnx(lock_key, 1)
    return false unless lock_author

    # デッドロック防止
    redis.expire(lock_key, 30)
    # 排他制御spec用コード
    sleep 0.5 if ENV['DELAY_FOR_TESTING']
    temporary_owner_id.value = user_id
    # 処理が終わったらロック解除
    redis.del(lock_key)
    true
  end

  def ticket_release(user_id)
    temporary_owner_id.clear if temporary_reserved? && temporary_owner?(user_id)
  end

  def qr_ticket_id_generate!
    update!(qr_ticket_id: AdmissionUuid.generate_uuid)
  end

  def display_hold_daily_schedule_id
    seat_area.seat_sale.hold_daily_schedule_id
  end

  def coordinate_seat_number
    if single?
      # 販売不可エリア
      non_sale_area
    elsif unit? && master_seat_unit&.seat_type == 'box'
      "#{(sub_code || '') + master_seat_unit&.unit_name}番"
    else
      '-'
    end
  end

  def coordinate_seat_type_name
    if single? || master_seat_unit&.seat_type == 'box'
      position.present? ? area_name + ' ' + position : area_name

    else
      area_name + ' ' + master_seat_unit&.unit_name
    end
  end

  # 購入時のorderを返す、決済完了までいかなかったり、管理者譲渡や譲渡で作成されたorderは除外
  # 返金の場合も、その後に管理画面譲渡ができるため購入時のorder対象から外す
  def purchase_order
    purchase_ticket_reserve&.order || orders.includes(:payment).purchase.find_by(payment: { payment_progress: :captured })
  end

  def extend_ownership_ttl(extend_ttl)
    temporary_owner_id.expire(extend_ttl)
  end

  private

  def non_sale_area
    if sub_code.present?
      "#{sub_code + seat_number.to_s}番"
    else
      "#{row.present? ? row + '列 ' : ''}#{seat_number}番"
    end
  end

  def transfer_uuid_generate!
    update!(transfer_uuid: SecureRandom.urlsafe_base64(32), qr_ticket_id: nil)
  end

  def lock_key
    "#{temporary_owner_id.key}_lock"
  end
end

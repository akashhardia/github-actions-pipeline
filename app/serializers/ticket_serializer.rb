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
class TicketSerializer < ActiveModel::Serializer
  attributes :id, :row, :seat_number,
             :status, :sales_type, :seat_type_id, :master_seat_unit_id, :sub_code

  # user_idが埋まっている場合は、購入済のステータスを返す
  # チケットが他のユーザーのcartに入っている場合は、一時保持のステータスを返す
  def status
    if object.user_id.present?
      'sold'
    elsif object.temporary_owner_id.value && object.temporary_owner_id.value != current_user_id
      'temporary_hold'
    else
      object.status
    end
  end

  private

  def current_user_id
    instance_options[:current_user_id]
  end
end

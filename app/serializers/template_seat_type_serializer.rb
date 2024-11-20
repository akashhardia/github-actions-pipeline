# frozen_string_literal: true

# == Schema Information
#
# Table name: template_seat_types
#
#  id                    :bigint           not null, primary key
#  price                 :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  master_seat_type_id   :bigint           not null
#  template_seat_sale_id :bigint           not null
#
# Indexes
#
#  index_template_seat_types_on_master_seat_type_id    (master_seat_type_id)
#  index_template_seat_types_on_template_seat_sale_id  (template_seat_sale_id)
#
# Foreign Keys
#
#  fk_rails_...  (master_seat_type_id => master_seat_types.id)
#  fk_rails_...  (template_seat_sale_id => template_seat_sales.id)
#
# 席種テンプレートのシリアライザ
class TemplateSeatTypeSerializer < ApplicationSerializer
  attributes :id, :name, :price
  has_many :template_seat_type_options, if: :relation?
end

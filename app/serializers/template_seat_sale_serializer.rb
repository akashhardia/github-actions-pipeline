# frozen_string_literal: true

# == Schema Information
#
# Table name: template_seat_sales
#
#  id          :bigint           not null, primary key
#  description :string(255)
#  immutable   :boolean          default(FALSE), not null
#  status      :integer          default("available"), not null
#  title       :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class TemplateSeatSaleSerializer < ApplicationSerializer
  attributes :id, :title, :description, :status, :immutable
  has_many :template_seat_types, if: :relation?

  attribute :created_at, if: :index?
  attribute :updated_at, if: :index?
  attribute :number_of_used, if: :index?

  attribute :per_seat_type_summaries, if: :show?

  def initialize(serializer, options = {})
    @instance_options = options
    super
  end

  def index?
    @instance_options[:action] == :index
  end

  def show?
    @instance_options[:action] == :show
  end

  def number_of_used
    object.seat_sales.count(&:on_sale?)
  end

  def per_seat_type_summaries
    object.template_seat_types.each_with_object([]) do |template_seat_type, result|
      is_single = MasterSeat.find_by(master_seat_type: template_seat_type.master_seat_type).single?
      options = template_seat_type.template_seat_type_options
      result << { id: template_seat_type.id, name: template_seat_type.name,
                  price: template_seat_type.price, options: options, is_single: is_single }
    end
  end

  def immutable
    object.template_immutable?
  end
end

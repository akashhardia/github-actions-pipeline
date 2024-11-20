# frozen_string_literal: true

# 販売テンプレート、席種テンプレート、エリアテンプレート、席種オプションテンプレートの複製
class TemplateDuplicator
  include ActiveModel::Model

  attr_accessor :origin_template_seat_sale, :new_template_seat_sale_title, :new_template_seat_sale_description

  def initialize(template_seat_sale_params)
    @origin_template_seat_sale = TemplateSeatSale.preload(
      template_seat_types: :template_seat_type_options,
      template_seat_areas: [template_seats: :template_seat_type]
    ).find(template_seat_sale_params[:id])
    @new_template_seat_sale_title = template_seat_sale_params[:title]
    @new_template_seat_sale_description = template_seat_sale_params[:description]
  end

  def duplicate_all_templates!
    ActiveRecord::Base.transaction do
      new_template_seat_sale = duplicate_template_seat_sale!
      duplicate_template_seat_types!(new_template_seat_sale)
      duplicate_template_seat_areas!(new_template_seat_sale)
      duplicate_template_seat_type_options!(new_template_seat_sale)
      duplicate_template_seats!(new_template_seat_sale)
    end
  end

  private

  def duplicate_template_seat_sale!
    TemplateSeatSale.create!(
      title: new_template_seat_sale_title,
      description: new_template_seat_sale_description,
      status: :available,
      immutable: false
    )
  end

  def duplicate_template_seat_types!(new_template_seat_sale)
    origin_template_seat_types = origin_template_seat_sale.template_seat_types
    new_template_seat_types = origin_template_seat_types.map do |origin_template_seat_type|
      TemplateSeatType.new(
        master_seat_type_id: origin_template_seat_type.master_seat_type_id,
        template_seat_sale_id: new_template_seat_sale.id,
        price: origin_template_seat_type.price
      )
    end

    TemplateSeatType.import! new_template_seat_types

    new_template_seat_types
  end

  def duplicate_template_seat_areas!(new_template_seat_sale)
    origin_template_seat_areas = origin_template_seat_sale.template_seat_areas
    new_template_seat_areas = origin_template_seat_areas.map do |origin_template_seat_area|
      TemplateSeatArea.new(
        template_seat_sale_id: new_template_seat_sale.id,
        master_seat_area_id: origin_template_seat_area.master_seat_area_id,
        displayable: origin_template_seat_area.displayable,
        entrance_id: origin_template_seat_area.entrance_id
      )
    end
    TemplateSeatArea.import! new_template_seat_areas
  end

  def duplicate_template_seat_type_options!(new_template_seat_sale)
    origin_template_seat_types = origin_template_seat_sale.template_seat_types
    new_template_seat_types = new_template_seat_sale.template_seat_types

    new_template_seat_type_options = new_template_seat_types.flat_map do |new_template_seat_type|
      origin_template_seat_type = origin_template_seat_types.find { |st| st.master_seat_type_id == new_template_seat_type.master_seat_type_id }
      origin_template_seat_type_options = origin_template_seat_type.template_seat_type_options
      origin_template_seat_type_options.map do |origin_template_seat_type_option|
        TemplateSeatTypeOption.new(
          template_seat_type_id: new_template_seat_type.id,
          title: origin_template_seat_type_option.title,
          price: origin_template_seat_type_option.price,
          description: origin_template_seat_type_option&.description
        )
      end
    end

    TemplateSeatTypeOption.import! new_template_seat_type_options
  end

  def duplicate_template_seats!(new_template_seat_sale)
    template_seat_types = new_template_seat_sale.template_seat_types
    template_seat_areas = new_template_seat_sale.template_seat_areas

    template_seats = origin_template_seat_sale.template_seat_areas.flat_map(&:template_seats).map do |origin_template_seat|
      master_seat_type_id = origin_template_seat.template_seat_type.master_seat_type_id
      master_seat_area_id = origin_template_seat.template_seat_area.master_seat_area_id

      template_seat_type = template_seat_types.find { |st| st.master_seat_type_id == master_seat_type_id }
      template_seat_area = template_seat_areas.find { |sa| sa.master_seat_area_id == master_seat_area_id }

      TemplateSeat.new(
        template_seat_type: template_seat_type,
        template_seat_area: template_seat_area,
        master_seat_id: origin_template_seat.master_seat_id,
        status: origin_template_seat.status
      )
    end

    TemplateSeat.import! template_seats
  end
end

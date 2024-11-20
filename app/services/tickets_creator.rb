# frozen_string_literal: true

# チケット関連モデルクリエーター
class TicketsCreator
  include ActiveModel::Model

  attr_accessor :hold_daily_schedule_id, :template_seat_sale_id, :sales_start_at, :sales_end_at, :admission_available_at, :admission_close_at

  validates :hold_daily_schedule_id, :template_seat_sale_id, :salesStartAt, :salesEndAt, :admissionAvailableAt, :admissionCloseAt, presence: true

  def initialize(tickets_params)
    @hold_daily_schedule_id = HoldDailySchedule.find(tickets_params[:hold_daily_schedule_id]).id
    @template_seat_sale_id = TemplateSeatSale.find(tickets_params[:template_seat_sale_id]).id
    @sales_start_at = tickets_params[:sales_start_at]
    @sales_end_at = tickets_params[:sales_end_at]
    @admission_available_at = tickets_params[:admission_available_at]
    @admission_close_at = tickets_params[:admission_close_at]
  end

  def create_all_tickets!
    ActiveRecord::Base.transaction do
      # チケット作成
      seat_sale = create_seat_sale!
      create_seat_types!(seat_sale)
      create_seat_areas!(seat_sale)
      create_tickets!(seat_sale)
      create_seat_type_options!(seat_sale)
    end
  end

  private

  def create_seat_sale!
    SeatSale.create!(
      hold_daily_schedule_id: hold_daily_schedule_id,
      template_seat_sale_id: template_seat_sale_id,
      sales_status: :before_sale,
      sales_start_at: sales_start_at,
      sales_end_at: sales_end_at,
      admission_available_at: admission_available_at,
      admission_close_at: admission_close_at
    )
  end

  def create_seat_types!(seat_sale)
    template_seat_types = TemplateSeatType.where(template_seat_sale_id: template_seat_sale_id)
    raise CustomError.new(http_status: :not_found, code: :incomplete_template), I18n.t('custom_errors.ticket.template_seat_type_blank') if template_seat_types.blank?

    seat_types = template_seat_types.map do |template_seat_type|
      SeatType.new(
        seat_sale_id: seat_sale.id,
        master_seat_type_id: template_seat_type.master_seat_type_id,
        template_seat_type_id: template_seat_type.id
      )
    end
    SeatType.import! seat_types
  end

  def create_seat_areas!(seat_sale)
    template_seat_areas = TemplateSeatArea.where(template_seat_sale_id: template_seat_sale_id)
    raise CustomError.new(http_status: :not_found, code: :incomplete_template), I18n.t('custom_errors.ticket.template_seat_area_blank') if template_seat_areas.blank?

    seat_areas = template_seat_areas.map do |template_seat_area|
      SeatArea.new(
        seat_sale_id: seat_sale.id,
        master_seat_area_id: template_seat_area.master_seat_area_id,
        displayable: template_seat_area.displayable,
        entrance_id: template_seat_area.entrance_id
      )
    end
    SeatArea.import! seat_areas
  end

  def create_tickets!(seat_sale)
    seat_types = SeatType.where(seat_sale: seat_sale)
    seat_areas = SeatArea.where(seat_sale: seat_sale)

    template_seat_sale = TemplateSeatSale.find(template_seat_sale_id)
    template_seats = template_seat_sale.template_seats.includes(:template_seat_type, :template_seat_area, :master_seat)
    raise CustomError.new(http_status: :not_found, code: :incomplete_template), I18n.t('custom_errors.ticket.template_seat_blank') if template_seats.blank?

    tickets = template_seats.map do |template_seat|
      # sql文を発行しないために配列のfindを使用する
      seat_type = seat_types.find { |st| st.master_seat_type_id == template_seat.template_seat_type.master_seat_type_id }
      seat_area = seat_areas.find { |sa| sa.master_seat_area_id == template_seat.template_seat_area.master_seat_area_id }
      # seat_typeとseat_areaが見つからない場合はカスタムエラーを上げる
      raise CustomError.new(http_status: :not_found, code: :incomplete_template), I18n.t('custom_errors.ticket.seat_type_or_seat_area_blank') if seat_type.blank? || seat_area.blank?

      Ticket.new(
        seat_type_id: seat_type.id,
        seat_area_id: seat_area.id,
        user_id: nil,
        row: template_seat.row,
        seat_number: template_seat.seat_number,
        sales_type: template_seat.sales_type,
        transfer_uuid: nil,
        master_seat_unit_id: template_seat.master_seat_unit_id,
        status: template_seat.status,
      )
    end

    Ticket.import! tickets
  end

  def create_seat_type_options!(seat_sale)
    template_seat_types = TemplateSeatType.where(template_seat_sale_id: template_seat_sale_id)
    template_seat_type_options = TemplateSeatTypeOption.includes(:template_seat_type).where(template_seat_type: template_seat_types)
    seat_types = seat_sale.seat_types
    seat_type_options = template_seat_type_options.map do |template_seat_type_option|
      # sql文が毎回走るのを回避するために配列のfindを使用
      seat_type = seat_types.find do |st|
        st.seat_sale_id == seat_sale.id && st.master_seat_type_id == template_seat_type_option.template_seat_type.master_seat_type_id
      end

      SeatTypeOption.new(
        seat_type_id: seat_type.id,
        template_seat_type_option_id: template_seat_type_option.id,
      )
    end

    SeatTypeOption.import! seat_type_options
  end
end

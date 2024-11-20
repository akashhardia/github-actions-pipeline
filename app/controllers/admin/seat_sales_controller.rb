# frozen_string_literal: true

module Admin
  # 管理画面開催デイリーコントローラ
  class SeatSalesController < ApplicationController
    before_action :snakeize_params
    before_action :set_seat_sale, except: [:index, :new, :create, :on_sale, :index_for_csv]

    def index
      hold_seat_sales = SeatSale.includes(:template_seat_sale, hold_daily_schedule: { hold_daily: :hold })
                                .where(hold_daily_schedules: { hold_dailies: { event_date: params[:event_date] } })
      seat_sales_by_type = case params[:type]
                           when 'before_sale'
                             hold_seat_sales.before_sale.page(params[:page] || 1).per(10)
                           when 'on_sale'
                             hold_seat_sales.on_sale.page(params[:page] || 1).per(10)
                           else
                             hold_seat_sales.page(params[:page] || 1).per(10)
                           end

      pagination = resources_with_pagination(seat_sales_by_type)
      serialized_seat_sales = ActiveModelSerializers::SerializableResource.new(seat_sales_by_type, each_serializer: SeatSaleSerializer, action: :index, key_transform: :camel_lower)
      render json: { seatSales: serialized_seat_sales, pagination: pagination }
    end

    def discontinue
      raise CustomError.new(I18n.t('seat_sales.not_sale'), http_status: :bad_request, code: :incorrect_seat_sale_status) unless @seat_sale.on_sale?

      @seat_sale.selling_discontinued!
      head :ok
    end

    def update
      @seat_sale.update!(sales_admission_params)

      head :ok
    end

    def show
      render json: @seat_sale, serializer: SeatSaleSerializer, key_transform: :camel_lower
    end

    def new
      if params[:hold_daily_schedule_id] && params[:template_seat_sale_id]
        # 選択可能な開催一覧
        hold_daily_schedule = HoldDailySchedule.find(params[:hold_daily_schedule_id].to_i)

        serialized_hold_daily_schedule = ActiveModelSerializers::SerializableResource.new(hold_daily_schedule, serializer: HoldDailyScheduleForCouponSerializer, key_transform: :camel_lower)

        template_seat_sale = TemplateSeatSale.select(:id, :title).find(params[:template_seat_sale_id].to_i)

        template_seat_sale_schedule = TemplateSeatSaleSchedule.target_find_by(hold_daily_schedule)

        render json: { holdDailySchedule: serialized_hold_daily_schedule,
                       templateSeatSale: template_seat_sale,
                       salesStartAt: Time.zone.now.strftime('%Y/%m/%d %H:%M:%S'),
                       salesEndTime: template_seat_sale_schedule.sales_end_time,
                       admissionAvailableTime: template_seat_sale_schedule.admission_available_time,
                       admissionCloseTime: template_seat_sale_schedule.admission_close_time }, status: :ok
        return
      end

      # 選択可能な開催一覧
      hold_daily_schedules = HoldDailySchedule.includes(:seat_sales, { hold_daily: :hold })
                                              .where(hold_daily: { daily_status: %w[before_held], event_date: Time.zone.today.. })
                                              .order('hold_daily.event_date desc')
                                              .filter { |h| h.available_seat_sale.blank? }
      serialized_hold_daily_schedules = ActiveModelSerializers::SerializableResource.new(hold_daily_schedules, each_serializer: HoldDailyScheduleForCouponSerializer, key_transform: :camel_lower)

      # 選択可能な販売テンプレート一覧
      template_seat_sales = TemplateSeatSale.available.select(:id, :title)

      render json: { holdDailySchedules: serialized_hold_daily_schedules, templateSeatSales: template_seat_sales }, status: :ok
    end

    def create
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.seat_sale.params_blank') if create_sales_params[:hold_daily_schedule_id].blank? || create_sales_params[:template_seat_sale_id].blank? || create_sales_params[:sales_start_at].blank?

      hold_daily_schedule = HoldDailySchedule.find(create_sales_params[:hold_daily_schedule_id])

      return render json: { result: I18n.t('seat_sales.exists') }, status: :unprocessable_entity if hold_daily_schedule.available_seat_sale.present?

      schedule = TemplateSeatSaleSchedule.target_find_by(hold_daily_schedule)

      event_date = hold_daily_schedule.hold_daily.event_date.to_s
      params = {
        hold_daily_schedule_id: create_sales_params[:hold_daily_schedule_id],
        template_seat_sale_id: create_sales_params[:template_seat_sale_id],
        sales_start_at: create_sales_params[:sales_start_at],
        sales_end_at: Time.zone.parse("#{event_date} #{schedule.sales_end_time}"),
        admission_available_at: Time.zone.parse("#{event_date} #{schedule.admission_available_time}"),
        admission_close_at: Time.zone.parse("#{event_date} #{schedule.admission_close_time}")
      }

      creator = TicketsCreator.new(params)
      creator.create_all_tickets!
    end

    def config_price
      seat_sale = SeatSale.includes(template_seat_sale: { template_seat_types: [:template_seat_type_options, :master_seat_type] }).find(params[:id])
      serialized_seat_sales = ActiveModelSerializers::SerializableResource.new(
        seat_sale.template_seat_sale, serializer: TemplateSeatSaleSerializer,
                                      include: { template_seat_types: :template_seat_type_options },
                                      relation: true, key_transform: :camel_lower
      )

      # 現在設定している販売テンプレートは除外する
      template_seat_sales = TemplateSeatSale.available.where.not(id: seat_sale.template_seat_sale_id).select(:id, :title)

      render json: { seatSale: serialized_seat_sales, templateSeatSales: template_seat_sales, changeFlag: seat_sale.before_sale? }
    end

    def on_sale
      seat_sales = SeatSale.where(id: on_sales_params[:ids])
      seat_sales.each do |seat_sale|
        return raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.seat_sale.tickets_on_sale_yet') if seat_sale.on_sale?
        return raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.seat_sale.sales_discontinued') if seat_sale.discontinued?
        return raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.seat_sale.promoter_year_empty') if seat_sale.hold_daily_schedule.promoter_year.blank?
        return raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.seat_sale.period_empty') if seat_sale.hold_daily_schedule.period.blank?
        return raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.seat_sale.round_empty') if seat_sale.hold_daily_schedule.round.blank?

        seat_sale.sales_status = 'on_sale'
      end

      ActiveRecord::Base.transaction do
        SeatSale.import! seat_sales.to_a, on_duplicate_key_update: [:sales_status]
      end

      head :ok
    end

    def duplicate
      return render json: { errors: I18n.t('seat_sales.not_copy') }, status: :unprocessable_entity unless @seat_sale.discontinued?
      return render json: { result: I18n.t('seat_sales.exists') }, status: :unprocessable_entity if @seat_sale.hold_daily_schedule.available_seat_sale.present?

      prevent_double_submit_with_id!(ticket_creator_lock_key) do
        tickets_params = {
          hold_daily_schedule_id: @seat_sale.hold_daily_schedule.id,
          template_seat_sale_id: @seat_sale.template_seat_sale.id,
          sales_start_at: @seat_sale.sales_start_at,
          sales_end_at: @seat_sale.sales_end_at,
          admission_available_at: @seat_sale.admission_available_at,
          admission_close_at: @seat_sale.admission_close_at
        }

        TicketsCreator.new(tickets_params).create_all_tickets!
      end

      render json: { copySeatSaleId: SeatSale.last.id }, status: :ok
    end

    def change_template
      return render json: { errors: I18n.t('seat_sales.not_change_template') }, status: :unprocessable_entity unless @seat_sale.before_sale?

      ActiveRecord::Base.transaction do
        prevent_double_submit_with_id!(ticket_creator_lock_key) do
          tickets_params = {
            hold_daily_schedule_id: @seat_sale.hold_daily_schedule.id,
            template_seat_sale_id: params[:template_seat_sale_id],
            sales_start_at: @seat_sale.sales_start_at,
            sales_end_at: @seat_sale.sales_end_at,
            admission_available_at: @seat_sale.admission_available_at,
            admission_close_at: @seat_sale.admission_close_at
          }

          TicketsCreator.new(tickets_params).create_all_tickets!
        end
        # 販売テンプレート差し替えた後、元の販売情報は削除する
        @seat_sale.destroy
      end

      render json: { changeSeatSaleId: SeatSale.last.id }, status: :ok
    end

    def bulk_refund
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.seat_sale.bulk_refund_unavailable') unless @seat_sale.discontinued?

      # SeatSaleに一括返金実行日時カラムを追加
      @seat_sale.update!(refund_at: Time.zone.now)

      # sidekiqでバックグラウンド非同期処理とする
      BulkRefundWorker.perform_async(@seat_sale.id)

      head :ok
    end

    def show_bulk_refund_result
      refund_data = if ActiveRecord::Type::Boolean.new.cast(params[:refund_error])
                      @seat_sale.orders.includes([:payment], [:user_coupon]).where.not(refund_error_message: nil).page(params[:page] || 1).per(10)
                    else
                      @seat_sale.orders.includes([:payment], [:user_coupon]).page(params[:page] || 1).per(10)
                    end
      pagination = resources_with_pagination(refund_data)
      serialized_refund_data = ActiveModelSerializers::SerializableResource.new(refund_data, each_serializer: BulkRefundResultSerializer, key_transform: :camel_lower)

      render json: { refundAt: @seat_sale.refund_at, refundEndAt: @seat_sale.refund_end_at, refundData: serialized_refund_data, pagination: pagination }, status: :ok
    end

    def index_for_csv
      seat_sales = SeatSale.includes(:template_seat_sale, hold_daily_schedule: { hold_daily: :hold })
                           .where(sales_status: %w[on_sale discontinued])
                           .where.not(hold_daily_schedule_id: nil)
                           .order(admission_available_at: 'DESC')

      serialized_seat_sales = ActiveModelSerializers::SerializableResource.new(seat_sales, each_serializer: SeatSaleSerializer, action: :index, key_transform: :camel_lower)
      render json: { seatSales: serialized_seat_sales }
    end

    def bulk_transfer
      raise CustomError.new(http_status: :bad_request, code: :bulk_transfer), I18n.t('custom_errors.seat_sale.bulk_transfer_unavailable') if @seat_sale.admission_close?

      target_tickets = @seat_sale.tickets.includes(seat_area: :seat_sale).not_for_sale.where(transfer_uuid: nil).where(seat_area: { displayable: params[:displayable] })

      ActiveRecord::Base.transaction do
        target_tickets.each(&:not_for_sale_ticket_uuid_generate!)
      end

      head :ok
    end

    def export_csv
      target_tickets = @seat_sale.tickets.includes(seat_area: :seat_sale).not_for_sale.where.not(transfer_uuid: nil).where(seat_area: { displayable: params[:displayable] })

      render json: target_tickets, each_serializer: CsvExportTransferTicketSerializer, action: :export_csv, key_transform: :camel_lower
    end

    private

    def set_seat_sale
      @seat_sale = SeatSale.find(params[:id])
    end

    def on_sales_params
      params.permit(ids: [])
    end

    def sales_admission_params
      params.permit(:sales_start_at, :sales_end_at, :admission_available_at, :admission_close_at)
    end

    def sales_params
      params.permit(:sales_start_at, :sales_end_at)
    end

    def admission_params
      params.permit(:admission_available_at, :admission_close_at)
    end

    def create_sales_params
      params.permit(:hold_daily_schedule_id, :template_seat_sale_id, :sales_start_at, :sales_end_at, :admission_available_at, :admission_close_at)
    end

    def ticket_creator_lock_key
      "TicketsCreator hold_daily_schedule_id: #{@hold_daily_schedule&.id || @seat_sale.hold_daily_schedule_id}"
    end
  end
end

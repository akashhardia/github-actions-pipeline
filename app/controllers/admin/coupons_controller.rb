# frozen_string_literal: true

require 'active_model'

module Admin
  # クーポンコントローラー
  class CouponsController < ApplicationController
    before_action :set_coupon, only: [:show, :export_csv, :update, :distribution]
    before_action :set_delete_coupon, only: [:destroy, :cancel]

    # クーポン一覧
    def index
      coupons = Coupon.includes(:template_coupon, :coupon_hold_daily_conditions, :coupon_seat_type_conditions, :master_seat_types, :hold_daily_schedules)
      coupons = case params[:type]
                when 'non_distributed'
                  # 未配布クーポン
                  coupons.includes(:user_coupons).where(user_coupons: { id: nil }).page(params[:page] || 1).per(10)
                when 'available'
                  # 利用可能なクーポン
                  coupons.available(Time.zone.now).page(params[:page] || 1).per(10)
                else
                  # すべてのクーポン
                  coupons.page(params[:page] || 1).per(10)
                end

      pagination = resources_with_pagination(coupons)

      serialized_coupons = ActiveModelSerializers::SerializableResource.new(coupons, each_serializer: CouponSerializer, action: :index, key_transform: :camel_lower)
      render json: { coupons: serialized_coupons, pagination: pagination }
    end

    def show
      render json: @coupon, serializer: ::CouponSerializer, key_transform: :camel_lower
    end

    # クーポン新規登録画面に必要な初期データを取得
    def new
      hold_daily_schedules = HoldDailySchedule.includes(:seat_sales).select do |hold_daily_schedule|
        hold_daily_schedule&.can_create_coupon?
      end
      # hold_daily_schedulesが取得できれば、先読みして渡す。取得できなければ空配列を返す
      hold_daily_schedules = hold_daily_schedules.present? ? HoldDailySchedule.includes(hold_daily: :hold).where(id: hold_daily_schedules) : []

      serialized_hold_daily_schedules = ActiveModelSerializers::SerializableResource.new(hold_daily_schedules, each_serializer: HoldDailyScheduleForCouponSerializer, key_transform: :camel_lower)
      serialized_master_seat_types = ActiveModelSerializers::SerializableResource.new(MasterSeatType.all, each_serializer: MasterSeatTypeSerializer, key_transform: :camel_lower)

      render json: { holdDailySchedules: serialized_hold_daily_schedules, masterSeatTypes: serialized_master_seat_types }, status: :ok
    end

    def create
      coupon = CouponCreator.new(params).create_coupon!
      render json: coupon, serializer: ::CouponSerializer, key_transform: :camel_lower, status: :ok
    end

    def export_csv
      users = @coupon.users

      profiles = Profile.where(user_id: users.ids)
      render json: profiles, each_serializer: ::ProfileSerializer, action: :export_csv, key_transform: :camel_lower, status: :ok
    end

    def destroy
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.coupons.already_canceled') if @delete_coupon.canceled_at?
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.coupons.unable_to_delete_after_distributed') if @delete_coupon.approved_at&.< Time.zone.now

      @delete_coupon.destroy!
      head :ok
    end

    def cancel
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.coupons.already_canceled') if @delete_coupon.canceled_at?

      @delete_coupon.update!(canceled_at: Time.zone.now)
      head :ok
    end

    def update
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.coupons.uneditable_after_canceled') if @coupon.canceled_at.present?

      template_coupon = @coupon.template_coupon
      template_coupon_params = params[:templateCoupon]
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.coupons.uneditable_after_approved') if template_coupon_params['rate'].present? &&
                                                                                                                     template_coupon.rate != template_coupon_params['rate'] && @coupon.approved_at.present?

      coupon_params = params[:coupon]
      hold_daily_schedule_ids = params[:holdDailyScheduleIds]
      master_seat_type_ids = params[:masterSeatTypeIds]
      ActiveRecord::Base.transaction do
        template_coupon.update!(title: template_coupon_params['title'],
                                rate: template_coupon_params['rate'] || template_coupon.rate,
                                note: template_coupon_params['note'])
        @coupon.update!(updated_at: Time.zone.now, available_end_at: coupon_params['availableEndAt'])
        update_coupon_hold_daily_conditions(hold_daily_schedule_ids, @coupon)
        update_coupon_seat_type_conditions(master_seat_type_ids, @coupon)
      end

      head :ok
    end

    def distribution
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.coupons.unable_to_distribute_after_canceled') if @coupon.canceled_at.present?
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.coupons.unable_to_distribute_again') if @coupon.approved_at.present?

      distribute_at = Time.zone.parse(params[:scheduledDistributedAt].to_s)

      raise CustomError.new(http_status: :bad_request, code: 'schedule_distributed_at_error'), I18n.t('custom_errors.coupons.distribute_at_is_blank') if distribute_at.blank?

      ActiveRecord::Base.transaction do
        user_restricted = params[:file].present? && params[:file] != 'undefined'

        # 配布のためのuser_couponの作成
        target_users = user_restricted ? coupon_selected_user_list(params[:file]) : coupon_all_users_list

        user_coupons = target_users.map do |user|
          UserCoupon.new(coupon_id: @coupon.id, user_id: user.id)
        end

        UserCoupon.import! user_coupons

        @coupon.update!(user_restricted: user_restricted, scheduled_distributed_at: distribute_at, approved_at: Time.zone.now)
      end

      head :ok
    end

    def used_coupon_count
      raise CustomError.new(http_status: :bad_request, code: 'bad_request'), I18n.t('custom_errors.coupons.ids_blank') unless params[:coupon_ids]

      coupon_list = coupon_id_params_list.map do |coupon_id|
        {
          id: coupon_id.to_i,
          numberOfUsedCoupons: Order.joins(:user_coupon).where(user_coupons: { coupon_id: coupon_id }).count,
          numberOfDistributedCoupons: UserCoupon.where(coupon_id: coupon_id).count
        }
      end
      render json: { coupons: coupon_list }
    end

    private

    def set_coupon
      @coupon = Coupon.find(params[:id])
    end

    def set_delete_coupon
      @delete_coupon = Coupon.find(params[:id])
    end

    def update_coupon_hold_daily_conditions(hold_daily_schedule_ids, coupon)
      coupon.coupon_hold_daily_conditions.destroy_all
      return unless hold_daily_schedule_ids.presence

      HoldDailySchedule.where(id: hold_daily_schedule_ids.map(&:to_i)).map do |hold_daily_schedule|
        coupon.coupon_hold_daily_conditions.create!(hold_daily_schedule_id: hold_daily_schedule.id)
      end
    end

    def update_coupon_seat_type_conditions(master_seat_type_ids, coupon)
      coupon.coupon_seat_type_conditions.destroy_all
      return unless master_seat_type_ids.presence

      MasterSeatType.where(id: master_seat_type_ids.map(&:to_i)).map do |master_seat_type|
        coupon.coupon_seat_type_conditions.create!(master_seat_type_id: master_seat_type.id)
      end
    end

    # csvファイルを元に対象のユーザーに対するuser_couponのリストを作成する
    def coupon_selected_user_list(file_params)
      begin
        target_ids = CSV.read(file_params, headers: true).map { |row| row['sixgram_id'] }
      rescue StandardError
        raise CustomError.new(http_status: :bad_request, code: 'csv_read_error'), I18n.t('custom_errors.coupons.csv_read_error')
      end
      target_users = User.where(sixgram_id: target_ids)
      raise CustomError.new(http_status: :bad_request, code: 'csv_read_error'), I18n.t('custom_errors.coupons.invalid_6gram_id') unless target_users.size == target_ids.size
      raise CustomError.new(http_status: :bad_request, code: 'csv_read_error'), I18n.t('custom_errors.coupons.no_users_to_distribute') if target_users.size.zero?

      target_users
    end

    # 全ユーザーに対してuser_couponのリストを作成する
    def coupon_all_users_list
      User.all
    end

    def coupon_id_params_list
      params[:coupon_ids]&.split(',')
    end
  end
end

# frozen_string_literal: true

module Admin
  # ユーザーコントローラー
  class UsersController < ApplicationController
    skip_before_action :require_login!, only: [:show]
    before_action :snakeize_params
    before_action :set_user, only: [:orders, :ticket_reserves, :send_unsubscribe_mail]

    def search
      profile = Profile.find_by(user_id: params[:id])

      render json: profile.user, each_serializer: Admin::UserSerializer, key_transform: :camel_lower
    end

    def search_new
      profiles = Profile.where('phone_number LIKE ?', "%#{params[:phone_number]}%")

      if profiles.empty?
        raise CustomError.new(http_status: :not_found, code: 'phone_number'), I18n.t('custom_errors.users.profile_blank')
      else
        users = profiles.map(&:user)
        render json: users, each_serializer: Admin::UserSerializer, key_transform: :camel_lower
      end
    end

    def orders
      # 譲渡については購入履歴では表示しないので外す
      orders = @user.orders
                    .includes(:payment, :ticket_reserves, seat_sale: { hold_daily_schedule: { hold_daily: :hold } })
                    .where(order_type: :purchase)

      render json: orders, each_serializer: Admin::OrderSerializer, action: :index, key_transform: :camel_lower
    end

    def ticket_reserves
      ticket_reserves = TicketReserve.includes(
        ticket: [:ticket_logs, :master_seat_unit, seat_area: :master_seat_area],
        seat_type_option: :template_seat_type_option,
        order: [:payment, { seat_sale: { hold_daily_schedule: { hold_daily: :hold } } }]
      ).admission_ticket(@user)

      render json: ticket_reserves.filter_ticket_reserves, each_serializer: Admin::TicketReserveIndexSerializer, key_transform: :camel_lower
    end

    def send_unsubscribe_mail
      target_user = User.find(params[:id])

      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.users.already_deleted') if target_user.deleted_at.present?

      ActiveRecord::Base.transaction do
        uuid = SecureRandom.urlsafe_base64(12)
        target_user.update!(unsubscribe_uuid: uuid, unsubscribe_mail_sent_at: Time.zone.now)
        AuthorizeMailer.send_unsubscribe_mail_to_user(target_user, uuid).deliver_later
      end

      head :ok
    end

    def export_csv
      users = User.all.includes(:profile)
      render json: users, each_serializer: CsvExportUserSerializer, action: :export_csv, key_transform: :camel_lower
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end

# frozen_string_literal: true

module Admin
  # 座席販売テンプレートコントローラ
  class TemplateSeatSalesController < ApplicationController
    before_action :set_template_seat_sale, only: [:edit, :update, :destroy]
    around_action :skip_bullet, if: -> { defined?(Bullet) }, only: [:index]

    # GET admin/template_seat_sales
    def index
      template_seat_sales = TemplateSeatSale.available.includes(:seat_sales, :template_seat_sale_schedules)

      template_seat_sales_by_type = case params[:type]
                                    when 'before_sale'
                                      # 承認待ち(statusがavailableのもののみ)
                                      template_seat_sales.mutable_templates.page(params[:page] || 1).per(10)
                                    when 'on_sale'
                                      # 販売中(statusがavailableのもののみ)
                                      template_seat_sales.already_on_sale.page(params[:page] || 1).per(10)
                                    else
                                      # 全て(statusがavailableのもののみ)
                                      template_seat_sales.page(params[:page] || 1).per(10)
                                    end

      pagination = resources_with_pagination(template_seat_sales_by_type)

      serialized_template_seat_sales = ActiveModelSerializers::SerializableResource.new(template_seat_sales_by_type, each_serializer: TemplateSeatSaleSerializer, action: :index, key_transform: :camel_lower)
      render json: { templateSeatSales: serialized_template_seat_sales, pagination: pagination }
    end

    # GET admin/template_seat_sales/1
    def show
      template_seat_sale = TemplateSeatSale.includes(template_seat_types: [:master_seat_type, :template_seat_type_options]).find(params[:id])
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.template_seat_sales.unavailable') if template_seat_sale.unavailable?

      render json: template_seat_sale,
             serializer: ::TemplateSeatSaleSerializer,
             action: :show,
             key_transform: :camel_lower
    end

    # GET admin/template_seat_sales/1/edit
    def edit
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.template_seat_sales.unavailable') if @template_seat_sale.unavailable?
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.template_seat_sales.immutable') if @template_seat_sale.template_immutable?

      render json: @template_seat_sale,
             serializer: ::TemplateSeatSaleSerializer, key_transform: :camel_lower
    end

    # PATCH admin/template_seat_sales/1
    def update
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.template_seat_sales.unavailable') if @template_seat_sale.unavailable?
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.template_seat_sales.immutable') if @template_seat_sale.template_immutable?

      if @template_seat_sale.update!(template_seat_sale_params)
        render json: @template_seat_sale, key_transform: :camel_lower
      else
        render json: @template_seat_sale.errors, status: :unprocessable_entity
      end
    end

    # DELETE admin/template_seat_sales/1
    def destroy
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.template_seat_sales.undeletable') if @template_seat_sale.template_immutable?
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.template_seat_sales.already_deleted') if @template_seat_sale.unavailable?

      @template_seat_sale.unavailable!
      head :ok
    end

    # テンプレート複製処理
    def duplicate_template_seat_sale
      template_duplicator = TemplateDuplicator.new(template_seat_sale_params)
      template_duplicator.duplicate_all_templates!

      head :ok
    end

    # テンプレートとオプションの作成/編集
    def create_template_seat_types
      template_seat_type = TemplateSeatType.find(params[:templateSeatTypeId])
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.template_seat_sales.cannot_be_added_and_edited') if template_seat_type.template_seat_sale.template_immutable?

      # TODO: ボーナスポイントの仕様が決まり次第、ボーナスポイントを更新するコードを実装
      ActiveRecord::Base.transaction do
        template_seat_type.update!(price: params[:templateSeatSale][:price])

        params[:templateSeatSale][:option]&.each do |option|
          if option[:id].present?
            TemplateSeatTypeOption.find(option[:id])
                                  .update!(title: option[:title],
                                           price: option[:price],
                                           description: option[:description])
          else
            TemplateSeatTypeOption.create!(title: option[:title],
                                           price: option[:price],
                                           description: option[:description],
                                           template_seat_type: template_seat_type)
          end
        end
      end
      head :ok
    end

    def destroy_template_seat_type_option
      template_seat_type_option = TemplateSeatTypeOption.find(params[:id])
      raise CustomError.new(http_status: :bad_request), I18n.t('custom_errors.template_seat_sales.undeletable') if template_seat_type_option.template_seat_sale.template_immutable?

      template_seat_type_option.destroy!
      head :ok
    end

    private

    def set_template_seat_sale
      @template_seat_sale = TemplateSeatSale.find(params[:id])
    end

    def template_seat_sale_params
      params.permit(:id, :title, :description)
    end
  end
end

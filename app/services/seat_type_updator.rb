# frozen_string_literal: true

# seat_type関連の更新時のサービスクラス
class SeatTypeUpdator
  include ActiveModel::Model

  attr_reader :seat_type, :params

  def initialize(seat_type, params)
    @seat_type = seat_type
    @params = params
  end

  def update_record!
    successful = true
    if params[:name] && params[:price]
      successful = false unless seat_type.master_seat_type.update(name: params[:name]) && seat_type.update(price: params[:price])
    elsif params[:name]
      successful = false unless seat_type.master_seat_type.update(name: params[:name])
    elsif params[:price]
      successful = false unless seat_type.update(price: params[:price])
    end
    successful
  end
end

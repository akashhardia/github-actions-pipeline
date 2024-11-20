# frozen_string_literal: true

# 座席購入のエラー
class SeatSalesError < CustomError
  http_status :bad_request
  code 'seat_sales_error'
end

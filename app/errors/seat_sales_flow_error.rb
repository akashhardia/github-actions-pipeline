# frozen_string_literal: true

# 座席購入フローのエラー
# "カートが空だった"等の、購入フローを1からやり直す必要がある場合に発生
class SeatSalesFlowError < CustomError
  http_status :bad_request
  code 'seat_sales_flow_error'
end

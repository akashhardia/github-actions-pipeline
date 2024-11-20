# frozen_string_literal: true

module V1
  module Gate
    # チケットを使って競技場に入場した利用者の情報を集計するAPI
    class TicketSummariesController < ApplicationController
      def show
        # リクエストサンプル GET "/v1/tickets/stadiums/:id/entered/date=20210109"
        hold = Hold.includes(hold_dailies: { hold_daily_schedules: { seat_sales: :orders } }).find_by(track_code: format_value(params[:id]))
        # 不正な競技場コード(DB上見つからない場合は404エラーを返す)
        return render json: { errors: [message: I18n.t('ticket.stadium_not_found')] }, status: :not_found if hold.blank?

        hold_totalizer = HoldTotalizer.new(hold)
        hold_totalizer.filter_by_date(Time.zone.parse(params[:data]))
        # 不正な日付(DB上見つからない場合は404エラーを返す)
        return render json: { errors: [message: I18n.t('ticket.data_for_this_date_not_found')] }, status: :not_found if hold_totalizer.hold_dailies.blank?

        render json: { data: { ticket_customer: hold_totalizer.order_total_number, ticket_amount: hold_totalizer.order_total_price } }
      end

      private

      # 1桁のnumber型で送られてきた場合、2桁のstring型に変換するためのメソッド
      def format_value(id)
        format('%02<number>d', number: id.to_i)
      end
    end
  end
end

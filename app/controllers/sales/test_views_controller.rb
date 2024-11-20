# frozen_string_literal: true

module Sales
  # テスト用のviewをレンダリングする
  class TestViewsController < ActionController::Base # rubocop:disable Rails/ApplicationController
    def charge_authorization
      # @charge_id = params[:charge_id]
      render :charge_authorization
    end
  end
end

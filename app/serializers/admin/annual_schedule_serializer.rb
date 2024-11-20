# frozen_string_literal: true

module Admin
  # 管理画面の購入履歴
  class AnnualScheduleSerializer < ActiveModel::Serializer
    attributes :id, :track_code, :first_day, :active, :created_at, :updated_at
  end
end

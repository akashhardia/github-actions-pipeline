# frozen_string_literal: true

# 開催の詳細のシリアライザ
class HoldDetailSerializer < ActiveModel::Serializer
  attributes :hold_days, :grade_code, :purpose_code, :repletion_code, :hold_status,
             :promoter_code, :promoter_year, :promoter_times, :promoter_section

  def hold_status
    I18n.t("activerecord.attributes.hold.hold_status.#{object.hold_status}")
  end
end

# frozen_string_literal: true

module V1
  module Mt
    # 年間スケジュールシリアルライザー
    class AnnualScheduleSerializer < ApplicationSerializer
      attributes :id, :event_date, :hold_days, :girl, :audience, :promoter_year_title, :promoter_year_title_en, :season, :round,
                 :active, :audience, :grade_code, :pre_day, :promoter_section, :promoter_times, :promoter_year, :time_zone, :track_code,
                 :pf_id, :created_at, :updated_at

      def promoter_year_title
        object.year_name
      end

      def promoter_year_title_en
        object.year_name_en
      end

      def season
        hold&.period
      end

      def round
        hold&.round
      end

      def created_at
        object.created_at.to_s
      end

      def updated_at
        object.updated_at.to_s
      end

      private

      def hold
        @hold ||= Hold.find_by(first_day: object.first_day)
      end
    end
  end
end

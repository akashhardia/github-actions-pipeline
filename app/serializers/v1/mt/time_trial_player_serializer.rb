# frozen_string_literal: true

module V1
  module Mt
    # タイムトライアル出走選手
    class TimeTrialPlayerSerializer < ActiveModel::Serializer
      attributes :id, :total_time, :rank, :player, :gear

      def total_time
        case object.total_time
        when 99.9999, 99.999
          nil
        else
          object.total_time&.to_f
        end
      end

      def rank
        object.ranking
      end

      def gear
        object.gear&.to_f
      end

      def player
        return nil if object.pf_player_id.blank?

        tt_result_player = Player.includes(:player_original_info)
                                 .where.not(player_original_info: { pf_250_regist_id: nil })
                                 .where.not(player_original_info: { last_name_en: nil })
                                 .where.not(player_original_info: { first_name_en: nil })
                                 .find_by(pf_player_id: object.pf_player_id)
        tt_result_player.blank? ? nil : ActiveModelSerializers::SerializableResource.new(tt_result_player, serializer: V1::Mt::PlayerDetailSerializer)
      end
    end
  end
end

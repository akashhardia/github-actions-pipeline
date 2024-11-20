# frozen_string_literal: true

# 指定したidに紐づくHoldPlayerを基準に過去のHoldPlayerを解決し、
# 基準にしたHoldPlayerの last_hold_player_id を更新する。
module LastHoldPlayerResolver
  class << self
    def resolve(hold_id:, player_id:)
      hold_player = HoldPlayer.preload(:hold, :player).find_by(hold_id: hold_id, player_id: player_id)
      return nil unless hold_player

      return hold_player.last_hold_player_id if hold_player&.last_hold_player_id

      last_hold_player = get_last_hold_player(hold_player)
      return nil unless last_hold_player

      hold_player.update!(last_hold_player: last_hold_player)
      last_hold_player.id
    end

    private

    def get_last_hold_player(hold_player)
      hold_players = HoldPlayer.where(player: hold_player.player)
      hold_players.joins!(:hold, :race_result_players)
      hold_players.merge!(RaceResultPlayer.where(pf_player_id: hold_player.player.pf_player_id))
      # to_sql # "SELECT `holds`.* FROM `holds` WHERE `holds`.`first_day` < ?"
      hold_players.merge!(Hold.where(first_day: ...hold_player.hold.first_day).order(first_day: :desc))
      hold_players.first
    end
  end
end

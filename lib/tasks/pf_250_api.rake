# frozen_string_literal: true

namespace :pf_250_api do
  desc '250PFより定期的に選手マスタ情報を取得し保存する。指定した日付以降更新された選手情報を取得する。引数はupdate, player_idどちらか一方のみ必須（両方は不可）。対象データがなければ、result_code=100でlist=[]が返る'
  task get_players_update: :environment do |task|
    PlatformSync.player_update(ENV['UPDATE'], ENV['PLAYER_ID'])
    Rails.logger.info(format('Rake task "%<task_name>s" ALL DONE !!', task_name: task.name))
  end

  desc '250PFより定期的に出走情報を取得し保存する。引数はYYYY_MM'
  task race_details_get: :environment do
    PlatformSync.race_details_get(ENV['YYYY_MM'])
  end

  desc '250PFより開催マスタ情報を取得し保存する。引数はUPDATE'
  task holding_word_codes_update: :environment do
    PlatformSync.holding_word_codes_update(ENV['UPDATE'])
  end

  desc '250PFより年間スケジュール情報を取得し保存する。引数はPROMOTER,PROMOTER_YEAR'
  task annual_schedule_update: :environment do
    PlatformSync.annual_schedule_update(ENV['PROMOTER'], ENV['PROMOTER_YEAR'])
  end

  desc '250PFより選手戦績を更新する。引数はUPDATE'
  task player_result_update: :environment do
    # 日付をもとに3日以内の開催を検索し更新する
    param_day = ENV['UPDATE'].present? ? ENV['UPDATE'].to_s.to_date : Time.zone.today
    pf_player_ids = Hold.includes(:mediated_players).where(first_day: (param_day - 3)..param_day).distinct.pluck('mediated_players.pf_player_id')
    next if pf_player_ids.blank?

    pf_player_ids.each do |id|
      PlatformSync.player_result_update(id)
      PlatformSync.player_race_result_get(id)
    end
  end
end

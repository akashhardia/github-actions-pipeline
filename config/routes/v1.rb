# frozen_string_literal: true

namespace :v1 do
  # =============================================================
  # mt
  # =============================================================
  scope module: :mt do
    get 'mt/datas/promoter_years' => 'datas#promoter_years'
    get 'mt/datas/seat_sales' => 'datas#seat_sales'
    get 'mt/datas/finalists' => 'datas#finalists'
    get 'mt/datas/annual_schedules' => 'datas#annual_schedules'
    get 'mt/datas/rounds' => 'datas#rounds'
    get 'mt/datas/mediated_players' => 'datas#mediated_players'
    get 'mt/datas/mediated_players_revision' => 'datas#mediated_players_revision'
    get 'mt/datas/time_trial_results' => 'datas#time_trial_results'
    get 'mt/datas/time_trial_results_revision' => 'datas#time_trial_results_revision'
    get 'mt/datas/races' => 'datas#races'
    get 'mt/datas/hold_daily_schedules' => 'datas#hold_daily_schedules'
    get 'mt/datas/player_detail' => 'datas#player_detail'
    get 'mt/datas/player_detail_revision' => 'datas#player_detail_revision'
    get 'mt/datas/past_races' => 'datas#past_races'
    get 'mt/datas/race_details' => 'datas#race_details'
    get 'mt/datas/search_sort_items' => 'datas#search_sort_items'
    get 'mt/datas/scheduled_seasons' => 'datas#scheduled_seasons'
    get 'mt/datas/races_revision' => 'datas#races_revision'
  end

  # =============================================================
  # portal_250 / notifications
  # =============================================================
  scope module: :portal_250 do
    post 'notifications/odds' => 'notifications#odds', as: :notifications_odds
    post 'notifications/vote' => 'notifications#vote', as: :notifications_vote
    post 'notifications/payoff' => 'notifications#payoff', as: :notifications_payoff
    post 'notifications/holding' => 'notifications#holding', as: :notifications_holding
  end

  scope module: :gate do
    # =============================================================
    # admission
    # =============================================================
    get 'tickets-qr/:ticket_id/validation' => 'admission#verify', as: :admission_verify
    post 'tickets-qr/:ticket_id/logs' => 'admission#update_log', as: :admission_update_log
    delete 'tickets-qr/:ticket_id/logs' => 'admission#update_clean_log', as: :admission_update_clean_log

    # =============================================================
    # ticket_summaries
    # =============================================================
    get 'tickets/stadiums/:id/entered' => 'ticket_summaries#show', as: :ticket_summaries
  end

  scope module: :sixgram do
    post 'payments' => 'payments#update'
  end
end

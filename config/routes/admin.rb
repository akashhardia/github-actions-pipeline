# frozen_string_literal: true

namespace :admin do # rubocop:disable Metrics/BlockLength
  # =============================================================
  # annual_schedules
  # =============================================================
  resources :annual_schedules, only: :index do
    member do
      put 'change_activation' => 'annual_schedules#change_activation'
    end
  end

  # =============================================================
  # cognito
  # =============================================================
  get '/login_check' => 'cognito#login_check'
  post '/login' => 'cognito#login'
  delete '/logout' => 'cognito#logout'

  # =============================================================
  # coupons
  # =============================================================
  post 'coupons/export_csv' => 'coupons#export_csv'
  get 'coupons/used_coupon_count' => 'coupons#used_coupon_count'
  resources :coupons, only: [:index, :show, :new, :create, :destroy, :update] do
    member do
      put 'cancel' => 'coupons#cancel'
      put 'distribution' => 'coupons#distribution'
    end
  end

  # =============================================================
  # campaigns
  # =============================================================
  resources :campaigns, only: [:index, :show, :new, :create, :update, :destroy] do
    member do
      put 'approve' => 'campaigns#approve'
      put 'terminate' => 'campaigns#terminate'
    end
  end

  # =============================================================
  # hold_dailies
  # =============================================================
  get 'hold_dailies/calendar' => 'hold_dailies#calendar'
  get 'hold_dailies/seat_sales' => 'seat_sales#index'
  resources :hold_dailies, only: [:index, :show] do
    member do
      get 'movie_ids' => 'hold_dailies#movie_ids', as: :movie_ids
      put 'movie_ids' => 'hold_dailies#movie_ids_update', as: :movie_ids_update
    end
  end

  # =============================================================
  # holds
  # =============================================================
  get '/holds' => 'holds#index'
  get '/holds/:id' => 'holds#show', as: :hold
  get '/holds/:id/detail' => 'holds#detail', as: :hold_detail
  get '/holds/:id/mediated_players' => 'holds#mediated_players', as: :mediated_players
  get '/holds/:id/tt_movie_yt_id' => 'holds#tt_movie_yt_id', as: :tt_movie_yt_id
  put '/holds/:id/tt_movie_yt_id' => 'holds#tt_movie_yt_id_update', as: :tt_movie_yt_id_update

  # =============================================================
  # races
  # =============================================================
  get '/races/:id' => 'races#show', as: :race
  get '/races/:id/race_players' => 'races#race_players', as: :race_players
  get '/races/:id/odds_info' => 'races#odds_info', as: :odds_info
  get '/races/:id/payoff_info' => 'races#payoff_info', as: :payoff_info
  put '/races/:id/update_free_text' => 'races#update_free_text', as: :update_free_text

  # =============================================================
  # seat_areas
  # =============================================================
  get '/seat_areas' => 'seat_areas#index', as: :seat_areas
  get '/seat_areas/:id' => 'seat_areas#show', as: :seat_area

  # =============================================================
  # seat_sales
  # =============================================================
  resources :seat_sales, only: [:show, :new, :create]
  get '/seat_sales/:id/config_price' => 'seat_sales#config_price', as: :config_price
  put 'seat_sales/:id/discontinue' => 'seat_sales#discontinue', as: :discontinue
  put 'seat_sales/on_sale' => 'seat_sales#on_sale'
  put 'seat_sales/:id/update' => 'seat_sales#update'
  put 'seat_sales/:id/bulk_refund' => 'seat_sales#bulk_refund', as: :bulk_refund
  get 'seat_sales/:id/show_bulk_refund_result' => 'seat_sales#show_bulk_refund_result', as: :show_bulk_refund_result
  post 'seat_sales/:id/duplicate' => 'seat_sales#duplicate', as: :duplicate_seat_sale
  post 'seat_sales/:id/change_template' => 'seat_sales#change_template', as: :change_template_seat_sale
  get 'seat_sales' => 'seat_sales#index_for_csv', as: :index_for_csv
  put 'seat_sales/:id/bulk_transfer' => 'seat_sales#bulk_transfer', as: :bulk_transfer
  get 'seat_sales/:id/export_csv' => 'seat_sales#export_csv', as: :transfer_export_csv

  # =============================================================
  # template_seat_areas
  # =============================================================
  get 'template_seat_areas' => 'template_seat_areas#index'
  get 'template_seat_areas/:id' => 'template_seat_areas#show', as: 'template_seat_area'

  # =============================================================
  # template_seat_sale_schedules
  # =============================================================
  get 'template_seat_sale_schedules' => 'template_seat_sale_schedules#index', as: :template_seat_sale_schedules
  put 'template_seat_sale_schedules' => 'template_seat_sale_schedules#update'

  # =============================================================
  # template_seat_sales
  # =============================================================
  post 'create_template_seat_types' => 'template_seat_sales#create_template_seat_types'
  post 'template_seat_sales/:id/duplicate' => 'template_seat_sales#duplicate_template_seat_sale', as: :duplicate_template_seat_sale
  delete 'destroy_template_seat_type_options/:id' => 'template_seat_sales#destroy_template_seat_type_option', as: :delete_template_seat_type_options
  resources :template_seat_sales, only: [:index, :show, :edit, :update, :destroy]

  # =============================================================
  # template_seats
  # =============================================================
  put 'template_seats/stop_selling' => 'template_seats#stop_selling', as: :template_seat_stop_selling
  put 'template_seats/release_from_stop_selling' => 'template_seats#release_from_stop_selling', as: :template_seat_release_from_stop_selling

  # =============================================================
  # tickets
  # =============================================================
  get 'tickets/export_csv' => 'tickets#export_csv', as: :tickets_export_csv
  get 'tickets' => 'tickets#index', as: :tickets_index
  get 'tickets/:id' => 'tickets#show', as: :ticket_show
  get 'tickets/:id/reserve_status' => 'tickets#reserve_status', as: :ticket_reserve_status
  get 'tickets/:id/logs' => 'tickets#logs', as: :ticket_logs
  get 'tickets/:id/info' => 'tickets#info', as: :ticket_info
  put 'tickets/stop_selling' => 'tickets#stop_selling', as: :ticket_stop_selling
  put 'tickets/release_from_stop_selling' => 'tickets#release_from_stop_selling', as: :ticket_release_from_stop_selling
  put 'tickets/transfer' => 'tickets#transfer', as: :ticket_transfer
  put 'tickets/transfer_cancel' => 'tickets#transfer_cancel', as: :ticket_transfer_cancel
  put 'tickets/:id/transfer/:transfer_uuid/cancel' => 'tickets#cancel', as: :transfer_cancel
  put 'tickets/:id/before_enter' => 'tickets#before_enter', as: :ticket_before_enter
  put 'tickets/:id/update_admission_disabled_at' => 'tickets#update_admission_disabled_at', as: :ticket_update_admission_disabled_at

  # =============================================================
  # players
  # =============================================================
  get 'players' => 'players#index', as: :players
  put 'players' => 'players#update'
  get 'players/export_csv' => 'players#export_csv', as: :player_export_csv
  get 'players/:id' => 'players#show', as: :player_detail
  get 'players/:id/result' => 'players#result', as: :player_result
  get 'players/:id/race_results' => 'players#race_results', as: :player_race_results

  # =============================================================
  # users
  # =============================================================
  get 'users/search' => 'users#search', as: :search_user
  get 'users/search_new' => 'users#search_new', as: :search_user_new
  get 'users/:id/orders' => 'users#orders', as: :orders_user
  get 'users/:id/ticket_reserves' => 'users#ticket_reserves', as: :ticket_reserves_user
  put 'users/send_unsubscribe_mail' => 'users#send_unsubscribe_mail', as: :send_unsubscribe_mail
  get 'users/export_csv' => 'users#export_csv', as: :users_export_csv
  get 'users/:id' => 'users#show', as: :users_show

  # =============================================================
  # orders
  # =============================================================
  get 'orders/export_csv' => 'orders#export_csv', as: :orders_export_csv
  get 'orders/:id' => 'orders#show', as: :orders_show
  get 'orders/:id/ticket_reserves' => 'orders#ticket_reserves', as: :ticket_reserves_order
  put 'orders/:id/ticket_refund' => 'orders#ticket_refund', as: :ticket_refund_order
  get 'orders/:id/charge_status' => 'orders#charge_status', as: :charge_status_order

  # =============================================================
  # admin_users
  # =============================================================
  post 'admin_users/sign_up' => 'admin_users#sign_up', as: :admin_user_sign_up
  post 'admin_users/confirm_sign_up' => 'admin_users#confirm_sign_up', as: :admin_user_confirm_sign_up
  put 'admin_users/forgot_password' => 'admin_users#forgot_password', as: :admin_user_forgot_password
  put 'admin_users/confirm_forgot_password' => 'admin_users#confirm_forgot_password', as: :admin_user_confirm_forgot_password
  get 'admin_users' => 'admin_users#index', as: :admin_users
  put 'admin_users/admin_enable_user' => 'admin_users#admin_enable_user', as: :admin_user_admin_enable_user
  put 'admin_users/admin_disable_user' => 'admin_users#admin_disable_user', as: :admin_user_admin_disable_user

  # =============================================================
  # external_api_logs
  # =============================================================
  get 'external_api_logs' => 'external_api_logs#index', as: :external_api_logs
  get 'external_api_logs/:id' => 'external_api_logs#show', as: :external_api_log

  # platform
  # =============================================================
  put 'platform/holds_update' => 'platform#holds_update'
  put 'platform/players_update' => 'platform#players_update'
  put 'platform/race_details_update' => 'platform#race_details_update'
  put 'platform/holding_word_codes_update' => 'platform#holding_word_codes_update'
  put 'platform/annual_schedule_update' => 'platform#annual_schedule_update'
  put 'platform/player_race_result_update' => 'platform#player_race_result_update'
  put 'platform/player_result_update' => 'platform#player_result_update'
  put 'platform/odds_info_update' => 'platform#odds_info_update'

  # =============================================================
  # retired_players
  # =============================================================
  resources :retired_players, only: [:create, :destroy]
end

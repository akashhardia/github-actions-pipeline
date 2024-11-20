# frozen_string_literal: true

namespace :sales do
  # =============================================================
  # carts
  # =============================================================
  get 'carts/purchase_confirmation' => 'carts#purchase_confirmation', as: :purchase_confirmation
  get 'carts/purchase_preview' => 'carts#purchase_preview', as: :purchase_preview
  get 'carts/seat_type_options_select' => 'carts#seat_type_options_select'
  post 'carts' => 'carts#create'

  # =============================================================
  # coupons
  # =============================================================
  get 'available_coupons' => 'coupons#available_coupons'
  resources :coupons, only: [:index]

  # =============================================================
  # hold_daily_schedules
  # =============================================================
  get 'hold_daily_schedules' => 'hold_daily_schedules#index'
  get 'hold_daily_schedules/:id/area_sales_info' => 'hold_daily_schedules#area_sales_info', as: :area_sales_info

  # =============================================================
  # orders
  # =============================================================
  get 'orders' => 'orders#index'
  post 'orders/pre_request' => 'orders#pre_request'
  post 'orders/pre_request_redirect' => 'orders#pre_request_redirect'
  get 'orders/capture2' => 'orders#capture2'
  get 'orders/purchase_complete' => 'orders#purchase_complete', as: :purchase_complete
  get 'orders/:id' => 'orders#show', as: :order
  post 'api/orders/update_order_status_from_new_system' => 'orders#update_order_status_from_new_system'
  post 'api/orders/capture_from_new_system' => 'orders#capture_from_new_system'

  # =============================================================
  # seat_areas
  # =============================================================
  get 'seat_areas/:id' => 'seat_areas#show'

  # =============================================================
  # test_views
  # =============================================================
  get 'test_views/charge_authorization' => 'test_views#charge_authorization' if Rails.env.development? || Rails.env.test?

  # =============================================================
  # ticket_reserves
  # =============================================================
  get 'ticket_reserves/:id/transfer_uuid' => 'ticket_reserves#transfer_uuid', as: :transfer_uuid
  resources :ticket_reserves, only: [:index, :show]

  # =============================================================
  # tickets
  # =============================================================
  get 'tickets/:transfer_uuid/receive' => 'tickets#receive_ticket'
  put 'ticket_reserves/:id/transfer' => 'tickets#transfer', as: :transfer_ticket
  put 'ticket_reserves/:id/transfer_cancel' => 'tickets#cancel', as: :transfer_cancel
  post 'tickets/:transfer_uuid/receive' => 'tickets#receive', as: :receive_ticket
  post 'tickets/:transfer_uuid/receive_admin_ticket' => 'tickets#receive_admin_ticket', as: :receive_admin_ticket

  # =============================================================
  # users
  # =============================================================
  get 'users/session_profile' => 'users#session_profile'
  get 'users' => 'users#show'
  get 'users/profile' => 'users#profile'
  get 'users/email' => 'users#email'
  get 'users/email_unchecked' => 'users#email_unchecked'
  put 'users/confirm' => 'users#confirm'
  put 'users' => 'users#update'
  put 'users/send_auth_code' => 'users#send_auth_code', as: :send_auth_code
  put 'users/email_verify/:uuid' => 'users#email_verify', as: :email_verify
  delete 'users/logout' => 'users#logout'
  put 'users/:unsubscribe_uuid/unsubscribe' => 'users#unsubscribe', as: :user_unsubscribe
  post 'users/token' => 'users#token', as: :user_token
  post 'api/users/search' => 'users#search_by_phone_number'
  post 'api/users/search_by_email' => 'users#search_by_email'
  get 'api/users/search_by_id' => 'users#search_by_id'
  post 'api/users/is_exist' => 'users#is_exist'
  post 'api/users/is_active' => 'users#is_active'

  get 'api/users/all_users' => 'users#all_users'
  post 'users/login_flow_0' => 'users#login_flow_0'
  post 'users/login_flow_1' => 'users#login_flow_1'
  post 'api/users/create_from_new_system' => 'users#create_from_new_system'
  post 'api/users/update_from_new_system' => 'users#update_from_new_system'
  post 'api/users/update' => 'users#update_from_new_system'
  resources :users, only: [:create]
end

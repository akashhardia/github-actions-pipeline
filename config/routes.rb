# frozen_string_literal: true

Rails.application.routes.draw do
  resources :holds, only: [:index, :show]
  get 'hold_daily_schedules' => 'hold_daily_schedules#index'
  get 'hold_daily_schedules/:id/area_sales_info' => 'hold_daily_schedules#area_sales_info', as: :area_sales_info

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development? || Rails.env.staging?

  namespace :healthz do
    get :liveness
    get :readiness
  end

  root 'healthz#liveness'

  draw(:admin)
  draw(:sales)
  draw(:v1)

  require 'sidekiq/web'
  mount Sidekiq::Web, at: '/sidekiq'
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: external_api_logs
#
#  id                   :bigint           not null, primary key
#  host                 :string(255)
#  path                 :string(255)
#  request_params       :text(65535)
#  response_http_status :integer
#  response_params      :text(4294967295)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
FactoryBot.define do
  factory :external_api_log do
    host { 'test-api.staging.6gram-pay.com' }
    path { '/user_auth/api/internal_link/charge' }
    request_params { '{"amount":"4000", "product_name":"PIST6 入場チケット", "redirect_uri":"http://localhost:3000/sales/orders/capture"}' }
    response_http_status { 200 }
    response_params { '{"charge_id":"ch_test_b93ae3901af562ca75f87c9d","get_url":"https://staging.6gram-pay.com/w/wallet/6gram/payment/pist6/ch_test_b93ae3901af562ca75f87c9d/init?token=eyJhbGciOiJIUzUxMiIsImtpZCI6InJlZ2lzd"}' }
  end
end

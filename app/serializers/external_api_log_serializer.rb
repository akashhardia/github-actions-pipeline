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
class ExternalApiLogSerializer < ApplicationSerializer
  attributes :id, :host, :path, :request_params, :response_http_status, :response_params, :created_at
end

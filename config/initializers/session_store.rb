# frozen_string_literal: true

key = '250_portal_session'

key += "_#{Rails.env}" if %i[development unstable staging].include?(Rails.env.to_sym)

servers = {
  host: (ENV['REDIS_HOST']).to_s,
  port: 6379,
  db: 2,
  namespace: 'sessions'
}

if %i[staging production].include?(Rails.env.to_sym)
  Rails.application.config.session_store :redis_store,
                                         key: key,
                                         servers: servers,
                                         expire_after: 10.years,
                                         secure: true,
                                         http_only: true,
                                         same_site: :none
else
  Rails.application.config.session_store :redis_store,
                                         key: key,
                                         servers: servers,
                                         http_only: true,
                                         expire_after: 10.years
end

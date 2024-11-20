# frozen_string_literal: true

redis = if Rails.env.test?
          Redis.new(url: "redis://#{ENV['REDIS_HOST']}/9", port: 6379)
        else
          Redis.new(url: "redis://#{ENV['REDIS_HOST']}/1", port: 6379)
        end

Redis::Objects.redis = redis
Redis.current = redis

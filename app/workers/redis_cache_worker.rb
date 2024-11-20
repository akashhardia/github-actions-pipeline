# frozen_string_literal: true

# レスポンス高速化のため非同期でキャッシュの中身を更新する
# See RedisCache
class RedisCacheWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(redis_url, cache_key, class_name, method_name, *args)
    redis = Redis.new(url: redis_url)
    key = "#{cache_key}:lock"
    return unless redis.setnx(key, 1)

    begin
      redis.expire(key, 10)
      RedisCacheWorker.fetch(redis_url, cache_key, class_name, method_name, *args)
    ensure
      redis.del(key)
    end
  end

  def self.fetch(redis_url, cache_key, class_name, method_name, *args)
    redis = Redis.new(url: redis_url)
    result = class_name.constantize.method(method_name)[*args]
    key = "#{cache_key}:cache"
    redis.set(key, result&.to_json)
    redis.expire(key, 30.days)
    result
  end
end

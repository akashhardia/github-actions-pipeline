# frozen_string_literal: true

# キャッシュを返しつつ、非同期にキャッシュを更新する。
# キャッシュがない場合は同期処理で返す。
class RedisCache
  def initialize(redis)
    @redis = redis
    @retry_count = 0
  end

  def fetch(cache_key, method, *args)
    cache = @redis.get("#{cache_key}:cache")
    if cache
      RedisCacheWorker.perform_async(@redis.id, cache_key, method.receiver, method.name, *args)
      return JSON.parse(cache, symbolize_names: true)
    end
    RedisCacheWorker.fetch(@redis.id, cache_key, method.receiver.to_s, method.name.to_s, *args)
  end
end

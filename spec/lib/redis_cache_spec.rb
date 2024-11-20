# frozen_string_literal: true

require 'rails_helper'
describe RedisCache do
  let(:redis_cahce) { described_class.new(redis) }
  let(:redis) { instance_double(Redis) }

  describe '#fetch' do
    subject(:fetch) { redis_cahce.fetch(cache_key, method, *args) }

    let(:cache_key) { 'hoge' }
    let(:method) { instance_double(Method) }
    let(:args) { 'fuga' }

    it '戻り値は Redis#get の結果で添字はシンボルであること' do
      allow(redis).to receive(:get).with("#{cache_key}:cache").and_return('{"hoge": "hogehoge", "fuga": "fugafuga"}')
      allow(redis).to receive(:id).and_return('piyo')
      allow(RedisCacheWorker).to receive(:fetch).with('piyo', cache_key, '', 'fetch', *args)
      allow(method).to receive(:receiver).and_return(described_class)
      allow(method).to receive(:name).and_return(:fetch)

      result = fetch

      expect(result[:hoge]).to eq 'hogehoge'
      expect(result[:fuga]).to eq 'fugafuga'
    end

    it 'Redis#get の結果が nil のときも正常に終了する' do
      allow(redis).to receive(:get).with("#{cache_key}:cache").and_return(nil)
      allow(redis).to receive(:id).and_return('piyo')
      allow(RedisCacheWorker).to receive(:fetch).with('piyo', cache_key, 'RedisCache', 'fetch', *args)
      allow(method).to receive(:receiver).and_return(described_class)
      allow(method).to receive(:name).and_return(:fetch)
      expect { fetch }.not_to raise_error
    end
  end
end

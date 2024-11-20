# frozen_string_literal: true

require 'rails_helper'
describe V1::Mt::PlayerDetailSerializer, type: :serializer do
  let(:serializer) { described_class.new(player) }
  let(:player) { create(:player) }

  describe '#round_result_list' do
    subject(:round_result_list) { serializer.round_result_list }

    it 'RedisCache#fetch を呼んでいること' do
      redis_cache_spy = instance_double(RedisCache)
      allow(redis_cache_spy).to receive(:fetch)
      allow(RedisCache).to receive(:new).and_return(redis_cache_spy)
      round_result_list

      expect(redis_cache_spy).to have_received(:fetch).with("V1::Mt::PlayerDetailSerializer#round_result_list(#{player.pf_player_id})", described_class.method(:generate_round_result_list), player.pf_player_id)
    end
  end
end

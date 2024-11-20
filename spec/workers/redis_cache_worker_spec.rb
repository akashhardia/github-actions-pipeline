# frozen_string_literal: true

require 'rails_helper'
describe RedisCacheWorker, type: :worker do
  describe 'perform' do
    subject(:perform) do
      described_class.new.perform(redis_url, cache_key, class_name, method_name, *args)
    end

    let(:redis_url) { 'hoge' }
    let(:cache_key) { 'fuga' }
    let(:class_name) { 'piyo' }
    let(:method_name) { 'piyopiyo' }
    let(:args) { %w[arg1 arg2] }
    let(:redis_spy) { instance_double(Redis) }
    let(:key) { cache_key + ':lock' }

    before do
      allow(redis_spy).to receive(:expire).with(key, 10)
      allow(redis_spy).to receive(:del).with(key)
      allow(Redis).to receive(:new).and_return(redis_spy)
    end

    context 'Redis#setnx が true の場合 ' do
      before do
        allow(redis_spy).to receive(:setnx).with(key, 1).and_return(true)
      end

      it '正常終了すること' do
        allow(described_class).to receive(:fetch).with(redis_url, cache_key, class_name, method_name, *args)

        expect { perform }.not_to raise_error
        expect(redis_spy).to have_received(:setnx).with(key, 1)
        expect(redis_spy).to have_received(:expire).with(key, 10)
        expect(redis_spy).to have_received(:del).with(key)
      end

      it 'RedisCacheWorker.fetch が例外を raise しても Redis#del が実行されること' do
        allow(described_class).to receive(:fetch).with(redis_url, cache_key, class_name, method_name, *args).and_raise(StandardError)

        expect { perform }.to raise_error(StandardError)
        expect(redis_spy).to have_received(:setnx).with(key, 1)
        expect(redis_spy).to have_received(:expire).with(key, 10)
        expect(redis_spy).to have_received(:del).with(key)
        expect(described_class).to have_received(:fetch).with(redis_url, cache_key, class_name, method_name, *args)
      end
    end

    it 'Redis#setnx が false の場合 Redis#del が実行されないこと' do
      allow(redis_spy).to receive(:setnx).with("#{cache_key}:lock", 1).and_return(false)
      allow(described_class).to receive(:fetch)

      expect { perform }.not_to raise_error
      expect(redis_spy).to have_received(:setnx).with("#{cache_key}:lock", 1)
      expect(redis_spy).not_to have_received(:expire)
      expect(redis_spy).not_to have_received(:del)
      expect(described_class).not_to have_received(:fetch)
    end
  end

  describe 'fetch' do
    subject(:fetch) do
      described_class.fetch(redis_url, cache_key, class_name, method_name, *args)
    end

    let(:redis_url) { 'hoge' }
    let(:cache_key) { 'fuga' }
    # モック化する際の「Cannot proxy frozen objects」エラーを回避するために dup が必要です。
    # 文字列を直接 dup すると rubocop に指摘されます。
    let(:class_name) { class_name_string.dup }
    let(:class_name_string) { 'piyo' }
    let(:method_name) { 'piyopiyo' }
    let(:args) { %w[arg1 arg2] }
    let(:redis_spy) { instance_double(Redis) }

    before do
      allow(redis_spy).to receive(:set)
      allow(redis_spy).to receive(:expire)
      allow(Redis).to receive(:new).and_return(redis_spy)
      method_spy = instance_double(Method)
      allow(method_spy).to receive(:[]).and_return(result)
      class_spy = instance_double(Class)
      allow(class_spy).to receive(:method).and_return(method_spy)
      allow(class_name).to receive(:constantize).and_return(class_spy)
    end

    context '引数で渡されたメソッドの実行結果が nil の場合' do
      let(:result) { nil }

      it 'Redis に nil がセットされること' do
        expect { fetch }.not_to raise_error
        key = cache_key + ':cache'
        expect(redis_spy).to have_received(:set).with(key, nil)
        expect(redis_spy).to have_received(:expire).with(key, 30.days)
      end
    end

    context '引数で渡されたメソッドの実行結果が nil ではない場合' do
      let(:result) { 'hogehoge' }

      it 'Redis に to_json 実行時の値がセットされること' do
        expect { fetch }.not_to raise_error
        key = cache_key + ':cache'
        expect(redis_spy).to have_received(:set).with(key, result.to_json)
        expect(redis_spy).to have_received(:expire).with(key, 30.days)
      end
    end
  end
end

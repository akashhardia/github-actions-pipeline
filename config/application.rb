# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
# require "sprockets/railtie"
require 'rails/test_unit/railtie'
require 'csv'
require_relative 'json_log_formatter'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Chiba250
  # Application setting
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # session管理をするため諸々のmiddlewareが必要
    config.api_only = false

    config.i18n.default_locale = :ja # デフォルト言語は日本語
    config.i18n.load_path += Dir[Rails.root.join('config/locales/**/*.{rb,yml}').to_s] # 複数のlocalファイル読み込み
    config.time_zone = 'Tokyo' # 表示時間
    config.active_record.default_timezone = :local # DB保存時のタイムゾーン

    # lib配下のファイルをdevelopmentではauto_load,productionではeager_laodする
    config.paths.add 'lib', eager_load: true
    config.generators do |g|
      g.test_framework :rspec, view_specs: false, helper_specs: false
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
    end

    # validatorのフォルダーを分ける時は、ここで読み込み先を指定しないとcontrollerでclassを読み込んでくれない
    config.autoload_paths += Dir["#{config.root}/app/validators/**/"]

    # ヘルスチェックジョブをホスト認証で弾かないように除外する
    config.host_authorization = { exclude: ->(request) { request.path =~ /healthcheck|healthz/ } }

    config.enum = config_for(:enum)
  end
end

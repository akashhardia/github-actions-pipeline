# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.3.2'
# Use mysql as the database for Active Record
gem 'mysql2'
# Use Puma as the app server
gem 'puma'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Active Model has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap'

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

gem 'active_model_serializers'

gem 'seed-fu'

## API Client
gem 'httparty'

## バルクインサート
gem 'activerecord-import'

# Redis
gem 'redis', '~> 4.0'
gem 'redis-actionpack'
gem 'redis-namespace'
gem 'redis-objects'

# paginate
gem 'kaminari'

# auth
gem 'jwt'

# AWS
gem 'aws-sdk-cognitoidentityprovider'
gem 'aws-sdk-rails'

gem 'sidekiq'

# logs in JSON format
gem 'lograge'

gem 'bugsnag'

group :development, :test, :staging do
  # stagingでの初期データ生成に必要なため
  gem 'faker', git: 'https://github.com/faker-ruby/faker.git', branch: 'master'
end

group :development, :test do
  # N+1問題の検出
  gem 'bullet'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'rspec-validator_spec_helper'

  # ソースコード内に'binding.pry'と記述することでステップ実行できるデバッガ
  gem 'pry-byebug'
  gem 'pry-doc'
  gem 'pry-rails'
  gem 'pry-stack_explorer'
end

group :development, :staging do
  gem 'listen'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'annotate'
  gem 'spring'
  gem 'spring-watcher-listen'

  # メール確認
  gem 'letter_opener_web'
end

group :development do
  # コーディングルールチェック
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec'
end

group :test do
  gem 'database_cleaner-active_record'
  gem 'simplecov', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

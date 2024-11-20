# frozen_string_literal: true

origins = case Rails.env.to_sym
          when :production
            [%r{\Ahttps://www\.pist6\.com\z}, %r{\Ahttps://admin\.pist6\.com\z}, %r{\Ahttps://ticket\.pist6\.com\z}, %r{\Ahttps://bet\.pist6\.com\z}, %r{\Ahttps://api\.bet\.pist6\.com\z}]
          when :staging
            [%r{\Ahttps://stg\.pist6\.com\z}, %r{\Ahttps://dev\.pist6\.com\z}, %r{\Ahttps://stg-admin\.pist6\.com\z}, %r{\Ahttps://stg-ticket\.pist6\.com\z}, %r{\Ahttps://pistsix\.jp\z}, %r{\Ahttps://stg-bet\.pist6\.com\z}, %r{\Ahttps://api\.stg-bet\.pist6\.com\z}, %r{\Ahttps://localhost:3000\z}, %r{\Ahttp://localhost:3000\z}]
          else
            %r{\Ahttp://localhost:\d{1,4}\z}
          end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins origins
    resource '*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :head, :options],
             credentials: true
  end
end

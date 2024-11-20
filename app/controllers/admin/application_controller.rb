# frozen_string_literal: true

module Admin
  # adminのApplicationControllerです
  class ApplicationController < ::ApplicationController
    include CognitoTokenAuth
    before_action :require_login!

    private

    # 分岐などで、どうしても警告が回避できない場合に使用
    def skip_bullet
      Bullet.enable = false
      yield
    ensure
      Bullet.enable = true
      Bullet.unused_eager_loading_enable = Rails.env.development?
    end
  end
end

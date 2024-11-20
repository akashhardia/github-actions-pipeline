# frozen_string_literal: true

# ヘルスチェック用endpointです
class HealthzController < ApplicationController
  def readiness
    head :ok
  end

  def liveness
    head :ok
  end
end

# frozen_string_literal: true

# アプリケーションレコード
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

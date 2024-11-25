# frozen_string_literal: true

require 'rake'

RSpec.configure do |config|
  config.before(:suite) do
    Rails.application.load_tasks
  end

  config.before do
    Rake.application.tasks.each(&:reenable)
  end
end

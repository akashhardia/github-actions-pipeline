# frozen_string_literal: true

RSpec::Matchers.define :include_keys do |keys|
  match do |expected_keys|
    expect(expected_keys - keys).to match_array([])
  end

  failure_message do |expected_keys|
    %(#{[expected_keys - keys]}が含まれていません)
  end
end

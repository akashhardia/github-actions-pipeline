# frozen_string_literal: true

# !-- sample usage --!
#
# let(:model_class) do
#   DummyValidatorHelper.generate(:start_at, :end_at) do
#     validates_with TimeRangeValidator, from: :start_at, to: :end_at
#   end
# end
#
# let(:model) { model_class.new(Time.current, Time.current + 1.days) }

module DummyValidatorHelper
  class << self
    def generate(*attribute_names, &block)
      Struct.new(*attribute_names) do
        include ActiveModel::Validations

        def self.name
          'DummyValidator'
        end

        instance_eval(&block)
      end
    end
  end
end

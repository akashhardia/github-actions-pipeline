# frozen_string_literal: true

# Serializerの共通処理を置く
class ApplicationSerializer < ActiveModel::Serializer
  def initialize(serializer, options = {})
    @instance_options = options
    super
  end

  def relation?
    @instance_options[:relation]
  end
end

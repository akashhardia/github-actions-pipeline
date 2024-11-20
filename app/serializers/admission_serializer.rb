# frozen_string_literal: true

# 入場API用のSerializerモデル
class AdmissionSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :status,
             :created_at, :updated_at, :ticket

  attribute :errors, if: :error_message

  def errors
    error_message
  end

  def error_message
    instance_options[:error_message]
  end
end

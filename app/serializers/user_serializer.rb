# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                       :bigint           not null, primary key
#  deleted_at               :datetime
#  email_auth_code          :string(255)
#  email_auth_expired_at    :datetime
#  email_verified           :boolean          default(FALSE), not null
#  unsubscribe_mail_sent_at :datetime
#  unsubscribe_uuid         :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  qr_user_id               :string(255)
#  sixgram_id               :string(255)      not null
#
# Indexes
#
#  index_users_on_sixgram_id  (sixgram_id) UNIQUE
#
class UserSerializer < ApplicationSerializer
  attributes :id, :email_verified

  def export_csv?
    @instance_options[:action] == :export_csv
  end

  # csv_exportでのみ使用する値
  attribute :sixgram_id, if: :export_csv?
end

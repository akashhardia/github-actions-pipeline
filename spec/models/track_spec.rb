# frozen_string_literal: true

# == Schema Information
#
# Table name: tracks
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  track_code :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe Track, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
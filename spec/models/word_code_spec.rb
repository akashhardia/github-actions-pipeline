# frozen_string_literal: true

# == Schema Information
#
# Table name: word_codes
#
#  id         :bigint           not null, primary key
#  code       :string(255)
#  identifier :string(255)      not null
#  name1      :string(255)
#  name2      :string(255)
#  name3      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  master_id  :string(255)      not null
#
# Indexes
#
#  index_word_codes_on_master_id  (master_id) UNIQUE
#
require 'rails_helper'

RSpec.describe WordCode, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

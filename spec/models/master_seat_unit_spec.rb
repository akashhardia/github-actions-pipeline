# frozen_string_literal: true

# == Schema Information
#
# Table name: master_seat_units
#
#  id         :bigint           not null, primary key
#  seat_type  :integer
#  unit_name  :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

describe MasterSeatUnit, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

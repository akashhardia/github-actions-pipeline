# frozen_string_literal: true

# == Schema Information
#
# Table name: vote_infos
#
#  id             :bigint           not null, primary key
#  vote_status    :integer
#  vote_type      :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  race_detail_id :bigint           not null
#
# Indexes
#
#  index_vote_infos_on_race_detail_id  (race_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_detail_id => race_details.id)
#
require 'rails_helper'

RSpec.describe VoteInfo, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

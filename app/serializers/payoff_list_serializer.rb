# frozen_string_literal: true

# == Schema Information
#
# Table name: payoff_lists
#
#  id             :bigint           not null, primary key
#  payoff         :integer
#  payoff_type    :integer
#  tip1           :string(255)      not null
#  tip2           :string(255)
#  tip3           :string(255)
#  vote_type      :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  race_detail_id :bigint           not null
#
# Indexes
#
#  index_payoff_lists_on_race_detail_id  (race_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (race_detail_id => race_details.id)
#
class PayoffListSerializer < ActiveModel::Serializer
  attributes :id, :payoff_type, :vote_type, :tip1, :tip2, :tip3, :payoff, :created_at, :updated_at
end

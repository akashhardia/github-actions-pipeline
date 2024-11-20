# frozen_string_literal: true

# == Schema Information
#
# Table name: players
#
#  id                :bigint           not null, primary key
#  area_code         :string(255)
#  birthday          :date
#  catchphrase       :string(255)
#  chest             :decimal(4, 1)
#  country_code      :string(255)
#  current_rank_code :string(255)
#  dash              :decimal(4, 2)
#  delete_day        :date
#  duration          :decimal(4, 2)
#  gender_code       :integer
#  graduate          :integer
#  height            :decimal(4, 1)
#  keirin_delete     :date
#  keirin_expiration :date
#  keirin_regist     :date
#  keirin_update     :date
#  lap_1000          :string(255)
#  lap_200           :string(255)
#  lap_400           :string(255)
#  leftgrip          :decimal(3, 1)
#  max_speed         :decimal(4, 2)
#  middle_delete     :date
#  middle_expiration :date
#  middle_regist     :date
#  middle_update     :date
#  name_en           :string(255)
#  name_jp           :string(255)
#  next_rank_code    :string(255)
#  player_class      :integer
#  regist_day        :date
#  regist_num        :integer
#  rightgrip         :decimal(3, 1)
#  spine             :decimal(5, 1)
#  thigh             :decimal(4, 1)
#  vital             :decimal(5, 1)
#  weight            :decimal(4, 1)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  pf_player_id      :string(255)
#
# Indexes
#
#  index_players_on_pf_player_id  (pf_player_id)
#
class PlayerSerializer < ApplicationSerializer
  attributes :pf_player_id

  # 選手一覧ページ、選手詳細ページでのみ使用する値
  attribute :id, if: :index_or_show?
  attribute :name_jp, if: :index_or_show?
  attribute :regist_num, if: :index_or_show?
  attribute :display, if: :index_or_show?
  attribute :retired_player_id, if: :show?
  attribute :created_at, if: :index_or_show?
  attribute :updated_at, if: :index_or_show?

  # csv_exportでのみ使用する値
  attribute :catchphrase, if: :export_csv?
  attribute :last_name_jp, if: :export_csv?
  attribute :first_name_jp, if: :export_csv?
  attribute :pf_250_regist_id, if: :export_csv?

  def index_or_show?
    @instance_options[:action] == :index || show?
  end

  def export_csv?
    @instance_options[:action] == :export_csv
  end

  def show?
    @instance_options[:action] == :show
  end

  # 表示可否、要件を詰めていため現在は全て表示可
  def display
    true
  end

  def last_name_jp
    object.player_original_info&.last_name_jp
  end

  def first_name_jp
    object.player_original_info&.first_name_jp
  end

  def catchphrase
    return '' if object.catchphrase == 'null' || object.catchphrase.nil?

    object.catchphrase
  end

  def retired_player_id
    object.retired_player&.id
  end
end

# frozen_string_literal: true

# 選手詳細情報
class PlayerDetailSerializer < ApplicationSerializer
  attributes :player_class, :regist_day, :delete_day, :keirin_regist, :keirin_update, :keirin_delete, :keirin_expiration,
             :middle_regist, :middle_update, :middle_delete, :middle_expiration, :name_jp, :name_en, :birthday, :gender_code,
             :country_code, :area_code, :graduate, :current_rank_code, :next_rank_code, :height, :weight, :chest, :thigh,
             :leftgrip, :rightgrip, :vital, :spine, :lap_200, :lap_400, :lap_1000, :max_speed, :dash, :duration,
             :last_name_jp, :first_name_jp, :last_name_en, :first_name_en, :speed, :stamina, :power, :technique, :mental,
             :growth, :original_record, :popular, :experience, :evaluation, :nickname, :comment, :season_best, :year_best, :round_best,
             :race_type, :major_title, :pist6_title, :free1, :free2, :free3, :free4, :free5, :free6, :free7, :free8

  delegate :last_name_jp, :first_name_jp, :last_name_en, :first_name_en, :speed, :stamina, :power, :technique, :mental,
           :growth, :original_record, :popular, :experience, :evaluation, :nickname, :comment, :season_best, :year_best, :round_best,
           :race_type, :major_title, :pist6_title, :free1, :free2, :free3, :free4, :free5, :free6, :free7, :free8, to: :object

  # 性別をword_codeから日本語にする
  def gender_code
    WordName.get_word_name('813', object.gender_code, 'jp')&.name
  end
end

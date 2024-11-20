# frozen_string_literal: true

# Platform250から通知を受けモデルを作成する
module PlatformNotificationSync
  class << self
    def odds_creator!(odds_params)
      race_detail = RaceDetail.find_by!(entries_id: odds_params[:entries_id])

      ActiveRecord::Base.transaction do
        odds_info = race_detail.odds_infos.create!(odds_info_params(odds_params))

        odds_params[:odds_list].each do |list|
          odds_list = odds_info.odds_lists.create!(odds_list_params(list))

          list[:odds].each do |odds|
            odds_list.odds_details.create!(odds_detail_params(odds))
          end
        end
      end
    end

    def close_time_update!(vote_params)
      ActiveRecord::Base.transaction do
        vote_params[:entries_id_list].each do |id_list_params|
          race_detail = RaceDetail.find_by!(entries_id: id_list_params[:entries_id], pf_hold_id: vote_params[:hold_id], hold_id_daily: vote_params[:hold_id_daily])

          race_detail.update!(close_time: id_list_params[:close_time])
        end
      end
    end

    def payoff_creator!(payoff_params)
      race_detail = RaceDetail.find_by!(entries_id: payoff_params[:entries_id])

      ActiveRecord::Base.transaction do
        payoff_params[:rank].each_with_index do |r, idx|
          # 同着があり、次の順位がない場合はnullが入る
          next if r.blank?

          # 同着はカンマで区切られているため、カンマで分割して作成する
          r.split(',').each { |num| race_detail.ranks.create!(car_number: num, arrival_order: idx + 1) }
        end

        payoff_params[:payoff_list].each do |list|
          race_detail.payoff_lists.create!(payoff_list_params(list))
        end
      end
    end

    private

    def odds_info_params(params)
      {
        entries_id: params[:entries_id],
        odds_time: params[:odds_time],
        fixed: params[:fixed]
      }
    end

    def odds_list_params(params)
      {
        vote_type: params[:vote_type].to_i,
        odds_count: params[:odds_count]
      }
    end

    def odds_detail_params(params)
      {
        tip1: params[:tip1],
        tip2: params[:tip2],
        tip3: params[:tip3],
        odds_val: params[:odds_val],
        odds_max_val: params[:odds_max_val]
      }
    end

    def payoff_list_params(params)
      {
        tip1: params[:tip1],
        tip2: params[:tip2],
        tip3: params[:tip3],
        payoff_type: params[:payoff_type].to_i,
        vote_type: params[:vote_type].to_i,
        payoff: params[:payoff]
      }
    end
  end
end

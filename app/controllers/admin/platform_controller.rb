# frozen_string_literal: true

module Admin
  # Platformコントローラ
  class PlatformController < ApplicationController
    before_action :snakeize_params

    def holds_update
      raise PfApiError, I18n.t('custom_errors.platform.holds_update.params_blank') if [params[:year], params[:month], params[:hold_id]].all?(&:blank?)
      raise PfApiError, I18n.t('custom_errors.platform.holds_update.require_year_and_month') if params[:year].blank? != params[:month].blank?
      raise PfApiError, I18n.t('custom_errors.platform.holds_update.input_either_year_and_month_or_hold_id') if [params[:year], params[:month], params[:hold_id]].all?(&:present?)

      PlatformSync.hold_update!(year: params[:year].presence, month: params[:month].presence, hold_id: params[:hold_id])
      head :ok
    end

    def players_update
      raise PfApiError, I18n.t('custom_errors.platform.players_update.params_blank') if [params[:update_date], params[:pf_player_id]].all?(&:blank?)
      raise PfApiError, I18n.t('custom_errors.platform.players_update.input_either_update_date_or_player_id') if [params[:update_date], params[:pf_player_id]].all?(&:present?)

      PlatformSync.player_update(params[:update_date].presence, params[:pf_player_id])
      head :ok
    end

    def race_details_update
      raise PfApiError, I18n.t('custom_errors.platform.race_details_update.params_blank') if params[:year_month].blank?
      raise PfApiError, I18n.t('custom_errors.platform.race_details_update.year_month_invalid') unless /[0-9]{4}_[0-9]{2}/.match?(params[:year_month])

      PlatformSync.race_details_get(params[:year_month])
      head :ok
    end

    def holding_word_codes_update
      raise PfApiError, I18n.t('custom_errors.platform.holding_word_codes_update.params_blank') if params[:update_date].blank?
      raise PfApiError, I18n.t('custom_errors.platform.holding_word_codes_update.update_date_invalid') unless /[0-9]{8}/.match?(params[:update_date])

      PlatformSync.holding_word_codes_update(params[:update_date])
      head :ok
    end

    def annual_schedule_update
      raise PfApiError, I18n.t('custom_errors.platform.annual_schedule_update.params_blank') if params[:promoter_code].blank? || params[:promoter_year].blank?

      PlatformSync.annual_schedule_update(params[:promoter_code], params[:promoter_year])
      head :ok
    end

    def player_race_result_update
      raise PfApiError, I18n.t('custom_errors.platform.player_race_result_update.player_id_blank') if params[:player_id].blank?

      PlatformSync.player_race_result_get(params[:player_id], params[:hold_id])
      head :ok
    end

    def player_result_update
      # 日付をもとに3日以内の開催を検索し更新する
      param_day = params.present? && params[:update_date].present? ? update_date_match(params[:update_date]) : Time.zone.today
      pf_player_ids = Hold.includes(:mediated_players)
                          .where(first_day: (param_day - 3)..param_day)
                          .distinct
                          .pluck('mediated_players.pf_player_id')
      raise PfApiError, I18n.t('custom_errors.platform.player_result_update.mediated_player_not_found') if pf_player_ids.blank?

      pf_player_ids.each { |pf_player_id| PlatformSync.player_result_update(pf_player_id) }
      head :ok
    end

    def odds_info_update
      raise PfApiError, I18n.t('custom_errors.platform.odds_info_update.params_blank') if params[:entries_id].blank?

      PlatformSync.odds_info_get(params[:entries_id])
      head :ok
    end

    private

    def update_date_match(params)
      raise PfApiError, I18n.t('custom_errors.platform.holding_word_codes_update.update_date_invalid') unless /[0-9]{8}/.match?(params)

      params.to_s.to_date
    end
  end
end

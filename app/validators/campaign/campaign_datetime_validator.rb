# frozen_string_literal: true

# class Campaign
# start_at(開始日時) ≦ end_at(予定終了日時)
# approved_at(承認日時) ≦ end_at(予定終了日時)
# terminated_at(停止日時) ≦ end_at(予定終了日時)
class CampaignDatetimeValidator < ActiveModel::Validator
  def validate(record)
    record.errors.add :start_at, :start_at_over_end_at if record.start_at.present? && record.end_at.present? && record.start_at > record.end_at
    record.errors.add :approved_at, :approved_at_over_end_at if record.approved_at.present? && record.end_at.present? && record.approved_at > record.end_at
    record.errors.add :terminated_at, :terminated_at_over_end_at if record.terminated_at.present? && record.end_at.present? && record.terminated_at > record.end_at
  end
end

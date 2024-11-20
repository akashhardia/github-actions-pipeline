# frozen_string_literal: true

# class Coupon
# scheduled_distributed_at(配布予定日時) が available_end_at(利用終了日時)を超えてはいけない
# approved_at(承認日時) が available_end_at(利用終了日時)を超えてはいけない
class CouponStartAtMustOverEndAtValidator < ActiveModel::Validator
  def validate(record)
    if record.scheduled_distributed_at.present? && record.available_end_at.present? && record.scheduled_distributed_at > record.available_end_at
      record.errors.add :scheduled_distributed_at, :scheduled_distributed_at_over_end_at
      record.errors.add :available_end_at, :available_end_at_before_start_at
    end
    record.errors.add :approved_at, :approved_at_over_end_at if record.approved_at.present? && record.available_end_at.present? && record.approved_at > record.available_end_at
  end
end

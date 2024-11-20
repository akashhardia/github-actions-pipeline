# frozen_string_literal: true

# 販売開始日が販売終了日を超えるのを防ぐバリデーション
class StartAtMustOverEndAtValidator < ActiveModel::Validator
  def validate(record)
    validate_sales_term(record)
    validate_admission_term(record)
  end

  def validate_sales_term(record)
    return if record.sales_start_at.blank? || record.sales_end_at.blank?
    return if record.sales_start_at < record.sales_end_at

    record.errors.add :sales_start_at, :sales_start_at_over_end_at
    record.errors.add :sales_end_at, :sales_end_at_before_start_at
  end

  def validate_admission_term(record)
    return if record.admission_available_at.blank? || record.admission_close_at.blank?
    return if record.admission_available_at < record.admission_close_at

    record.errors.add :admission_available_at, :admission_available_at_over_close_at
    record.errors.add :admission_close_at, :admission_close_before_available_at
  end
end

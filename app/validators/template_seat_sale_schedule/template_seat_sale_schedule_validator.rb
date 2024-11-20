# frozen_string_literal: true

# 「入場開始時刻（admission_available_time） < 入場終了時刻（admission_close_time）」、
# 「販売終了時刻（sales_end_time） < 入場終了時刻（admission_close_time）」を保証するバリデーション
class TemplateSeatSaleScheduleValidator < ActiveModel::Validator
  def validate(record)
    validate_admission_available_and_close_time(record)
    validate_sales_and_admission_time(record)
  end

  def validate_admission_available_and_close_time(record)
    return if record.admission_available_time.blank? || record.admission_close_time.blank?
    return if record.admission_available_time < record.admission_close_time

    record.errors.add :admission_available_time, :admission_available_time_over_close_time
  end

  def validate_sales_and_admission_time(record)
    return if record.sales_end_time.blank? || record.admission_close_time.blank?
    return if record.sales_end_time < record.admission_close_time

    record.errors.add :sales_end_time, :sales_end_time_over_admission_close_time
  end
end

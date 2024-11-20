# frozen_string_literal: true

require 'rails_helper'

describe StartAtMustOverEndAtValidator, type: :validator do
  let(:hold_daily_schedule) { create(:hold_daily_schedule) }
  let(:template_seat_sale) { create(:template_seat_sale) }
  let(:attribute_names) { [:sales_start_at, :sales_end_at] }
  let(:sales_start_at) { Time.zone.now + 7.hours }

  describe 'seat_sale更新' do
    subject(:build_seat_sale) { build(:seat_sale, sales_start_at: sales_start_at, sales_end_at: sales_end_at, hold_daily_schedule: hold_daily_schedule, template_seat_sale: template_seat_sale) }

    context '販売終了時間が販売開始時間を超えていた場合は更新可能' do
      let(:sales_end_at) { Time.zone.now + 8.hours }

      it { is_expected.to be_valid }
    end

    context '販売開始時間が販売終了時間を超えていた場合は更新不可' do
      let(:sales_end_at) { Time.zone.now + 6.hours }

      it { is_expected.not_to be_valid }
    end
  end
end

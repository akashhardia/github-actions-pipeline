# frozen_string_literal: true

# == Schema Information
#
# Table name: seat_sales
#
#  id                     :bigint           not null, primary key
#  admission_available_at :datetime         not null
#  admission_close_at     :datetime         not null
#  force_sales_stop_at    :datetime
#  refund_at              :datetime
#  refund_end_at          :datetime
#  sales_end_at           :datetime         not null
#  sales_start_at         :datetime         not null
#  sales_status           :integer          default("before_sale"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  hold_daily_schedule_id :bigint
#  template_seat_sale_id  :bigint
#
# Indexes
#
#  index_seat_sales_on_hold_daily_schedule_id  (hold_daily_schedule_id)
#  index_seat_sales_on_template_seat_sale_id   (template_seat_sale_id)
#
# Foreign Keys
#
#  fk_rails_...  (hold_daily_schedule_id => hold_daily_schedules.id)
#  fk_rails_...  (template_seat_sale_id => template_seat_sales.id)
#
require 'rails_helper'

RSpec.describe SeatSale, type: :model do
  let(:hold_daily_schedule) { create(:hold_daily_schedule) }

  describe 'validationの確認' do
    let(:template_seat_sale) { create(:template_seat_sale) }

    it 'admission_available_atがなければerrorになること' do
      seat_sale = described_class.new(admission_close_at: Time.zone.tomorrow, sales_end_at: Time.zone.tomorrow, sales_start_at: Time.zone.yesterday, hold_daily_schedule: hold_daily_schedule, template_seat_sale: template_seat_sale)
      expect(seat_sale.valid?).to eq false
    end

    it 'admission_close_atがなければerrorになること' do
      seat_sale = described_class.new(admission_available_at: Time.zone.tomorrow, sales_end_at: Time.zone.tomorrow, sales_start_at: Time.zone.yesterday, hold_daily_schedule: hold_daily_schedule, template_seat_sale: template_seat_sale)
      expect(seat_sale.valid?).to eq false
    end

    it 'sales_end_atがなければerrorになること' do
      seat_sale = described_class.new(admission_close_at: Time.zone.tomorrow, admission_available_at: Time.zone.tomorrow, sales_start_at: Time.zone.yesterday, hold_daily_schedule: hold_daily_schedule, template_seat_sale: template_seat_sale)
      expect(seat_sale.valid?).to eq false
    end

    it 'sales_start_atがなければerrorになること' do
      seat_sale = described_class.new(admission_available_at: Time.zone.tomorrow, sales_end_at: Time.zone.tomorrow, admission_close_at: Time.zone.yesterday, hold_daily_schedule: hold_daily_schedule, template_seat_sale: template_seat_sale)
      expect(seat_sale.valid?).to eq false
    end

    it 'hold_daily_scheduleがなければerrorになること' do
      seat_sale = described_class.new(admission_available_at: Time.zone.tomorrow, admission_close_at: Time.zone.tomorrow, sales_end_at: Time.zone.tomorrow, sales_start_at: Time.zone.yesterday, template_seat_sale: template_seat_sale)
      expect(seat_sale.valid?).to eq false
    end

    it 'template_seat_saleがなければerrorになること' do
      seat_sale = described_class.new(admission_available_at: Time.zone.tomorrow, admission_close_at: Time.zone.tomorrow, sales_end_at: Time.zone.tomorrow, sales_start_at: Time.zone.yesterday, hold_daily_schedule: hold_daily_schedule)
      expect(seat_sale.valid?).to eq false
    end
  end

  describe '#check_sales_schedule?' do
    let(:user) { create(:user) }
    let(:seat_type) { create(:seat_type, hold_daily_schedule: hold_daily_schedule) }

    it '販売期間内の場合' do
      seat_sale = create(:seat_sale, hold_daily_schedule: hold_daily_schedule, sales_start_at: Time.zone.yesterday, sales_end_at: Time.zone.tomorrow)
      expect(seat_sale.check_sales_schedule?).to be true
    end

    it '販売期間内ではない場合' do
      seat_sale = create(:seat_sale, hold_daily_schedule: hold_daily_schedule, sales_start_at: Time.zone.yesterday - 1, sales_end_at: Time.zone.yesterday)
      expect(seat_sale.check_sales_schedule?).to be false
    end
  end

  describe '#available?' do
    subject(:available?) { seat_sale.available? }

    let(:seat_sale) { create(:seat_sale, :in_term, sales_status: sales_status) }

    context 'sales_statusがon_saleの場合' do
      let(:sales_status) { :on_sale }

      it 'trueであること' do
        expect(available?).to be true
      end
    end

    context 'sales_statusがon_saleではない場合' do
      let(:sales_status) { :before_sale }

      it 'falseであること' do
        expect(available?).to be false
      end
    end

    context 'sales_statusがon_saleで販売期間外の場合' do
      let(:seat_sale) { create(:seat_sale, :out_of_term, sales_status: sales_status) }
      let(:sales_status) { :on_sale }

      it 'falseであること' do
        expect(available?).to be false
      end
    end
  end

  describe '#can_create_coupon?' do
    subject(:can_create_coupon?) { seat_sale.can_create_coupon? }

    let(:seat_sale) { create(:seat_sale, :in_term, sales_status: sales_status) }

    context 'sales_statusがon_saleの場合' do
      let(:sales_status) { :on_sale }

      it 'trueであること' do
        expect(can_create_coupon?).to be true
      end
    end

    context 'sales_statusがbefore_saleの場合' do
      let(:sales_status) { :before_sale }

      it 'trueであること' do
        expect(can_create_coupon?).to be true
      end
    end

    context 'sales_statusがdiscontinuedの場合' do
      let(:sales_status) { :discontinued }

      it 'falseであること' do
        expect(can_create_coupon?).to be false
      end
    end

    context 'sales_statusがon_saleで販売終了日を過ぎている場合' do
      let(:seat_sale) { create(:seat_sale, :out_of_term, sales_status: sales_status) }
      let(:sales_status) { :on_sale }

      it 'falseであること' do
        expect(can_create_coupon?).to be false
      end
    end

    context 'sales_statusがbefore_saleで販売終了日を過ぎている場合' do
      let(:seat_sale) { create(:seat_sale, :out_of_term, sales_status: sales_status) }
      let(:sales_status) { :before_sale }

      it 'falseであること' do
        expect(can_create_coupon?).to be false
      end
    end
  end

  describe '#admission_available?' do
    subject(:admission_available?) { seat_sale.admission_available? }

    context '開場後の場合' do
      let(:seat_sale) { create(:seat_sale, admission_available_at: Time.zone.now - 1.hour) }

      it 'trueであること' do
        expect(admission_available?).to be true
      end
    end

    context '開場前の場合' do
      let(:seat_sale) { create(:seat_sale, admission_available_at: Time.zone.now + 1.hour) }

      it 'falseであること' do
        expect(admission_available?).to be false
      end
    end
  end

  describe '#admission_close?' do
    subject(:admission_close?) { seat_sale.admission_close? }

    context '閉場後の場合' do
      let(:seat_sale) { create(:seat_sale, :after_closing) }

      it 'trueであること' do
        expect(admission_close?).to be true
      end
    end

    context '閉場前の場合' do
      let(:seat_sale) { create(:seat_sale, :in_admission_term) }

      it 'falseであること' do
        expect(admission_close?).to be false
      end
    end
  end

  describe '#already_on_sale?' do
    subject(:already_on_sale?) { seat_sale.already_on_sale? }

    context '販売開始後の場合' do
      let(:seat_sale) { create(:seat_sale, sales_start_at: Time.zone.now - 1.hour, sales_status: sales_status) }

      context 'sales_statusがon_saleの時' do
        let(:sales_status) { :on_sale }

        it 'trueであること' do
          expect(already_on_sale?).to be true
        end
      end

      context 'sales_statusがon_saleではない時' do
        let(:sales_status) { :before_sale }

        it 'falseであること' do
          expect(already_on_sale?).to be false
        end
      end
    end

    context '販売開始前の場合' do
      let(:seat_sale) { create(:seat_sale, sales_start_at: Time.zone.now + 1.hour, sales_status: :on_sale) }

      it 'falseであること' do
        expect(already_on_sale?).to be false
      end
    end
  end

  describe '#selling_discontinued!' do
    subject(:selling_discontinued!) { seat_sale.selling_discontinued! }

    let(:seat_sale) { create(:seat_sale, :available) }

    it 'sales_statusがdiscontinuedに変更されること' do
      expect { selling_discontinued! }.to change(seat_sale, :sales_status).from('on_sale').to('discontinued')
    end

    context '販売開始後の場合' do
      it '販売中断日時が更新されていること' do
        expect { selling_discontinued! }.to change { seat_sale.force_sales_stop_at.present? }.from(false).to(true)
      end
    end

    context '販売開始前の場合' do
      let(:seat_sale) { create(:seat_sale, sales_start_at: Time.zone.now + 1.hour, sales_status: :on_sale) }

      it '販売中断日時が更新されていないこと' do
        expect { selling_discontinued! }.not_to change { seat_sale.force_sales_stop_at.present? }
      end
    end

    context '販売未承認の場合' do
      let(:seat_sale) { create(:seat_sale, sales_start_at: Time.zone.now - 1.hour, sales_status: :before_sale) }

      it '販売中断日時が更新されていないこと' do
        expect { selling_discontinued! }.not_to change { seat_sale.force_sales_stop_at.present? }
      end
    end
  end

  describe '#accounting_target?' do
    subject(:accounting_target?) { seat_sale.accounting_target? }

    context '販売開始後の場合' do
      let(:seat_sale) { create(:seat_sale, sales_start_at: Time.zone.now - 1.hour, sales_status: :on_sale) }

      it 'trueであること' do
        expect(accounting_target?).to be true
      end
    end

    context '販売開始後に販売中止した場合' do
      let(:seat_sale) { create(:seat_sale, force_sales_stop_at: Time.zone.now - 1.hour, sales_start_at: Time.zone.now - 2.hours, sales_status: :discontinued) }

      it 'trueであること' do
        expect(accounting_target?).to be true
      end
    end

    context '販売開始前の場合' do
      let(:seat_sale) { create(:seat_sale, sales_start_at: Time.zone.now + 1.hour, sales_status: :on_sale) }

      it 'falseであること' do
        expect(accounting_target?).to be false
      end
    end

    context '販売開始前に販売中止した場合' do
      let(:seat_sale) { create(:seat_sale, sales_start_at: Time.zone.now + 1.hour, sales_status: :discontinued) }

      it 'falseであること' do
        expect(accounting_target?).to be false
      end
    end
  end

  describe '#sales_progress' do
    subject(:sales_progress) { seat_sale.sales_progress }

    let(:seat_sale) { create(:seat_sale, sales_status: sales_status, sales_start_at: sales_start_at, sales_end_at: sales_end_at) }

    context '(前, 前) 現在時刻が販売開始時間より前、販売終了時間より前であるとき' do
      let(:sales_start_at) { Time.zone.now + 1.hour }
      let(:sales_end_at) { Time.zone.now + 2.hours }

      context '販売承認済みの場合' do
        let(:sales_status) { :on_sale }

        it '販売待機中の販売進捗ステータスが返ること' do
          expect(sales_progress).to eq :before_sale
        end
      end

      context '販売未承認の場合' do
        let(:sales_status) { :before_sale }

        it '販売未承認の販売進捗ステータスが返ること' do
          expect(sales_progress).to eq :unapproved_sale
        end
      end

      context '販売中止の場合' do
        let(:sales_status) { :discontinued }

        it '販売中止の販売進捗ステータスが返ること' do
          expect(sales_progress).to eq :discontinued
        end
      end
    end

    context '(後, 後) 現在時刻が販売開始時間より後、販売終了より後であるとき' do
      let(:sales_start_at) { Time.zone.now - 2.hours }
      let(:sales_end_at) { Time.zone.now - 1.hour }

      context '販売承認済みの場合' do
        let(:sales_status) { :on_sale }

        it '販売中の販売進捗ステータスが返ること' do
          expect(sales_progress).to eq :end_of_sale
        end
      end

      # 販売終了時間を過ぎていても、販売はしてないはずなのでunapproved_sale
      context '販売未承認の場合' do
        let(:sales_status) { :before_sale }

        it '販売未承認の販売進捗ステータスが返ること' do
          expect(sales_progress).to eq :unapproved_sale
        end
      end

      context '販売中止の場合' do
        let(:sales_status) { :discontinued }

        it '販売中止の販売進捗ステータスが返ること' do
          expect(sales_progress).to eq :discontinued
        end
      end
    end

    context '(後, 前) 現在時刻が販売開始時間より後、販売終了時間より前であるとき' do
      let(:sales_start_at) { Time.zone.now - 1.hour }
      let(:sales_end_at) { Time.zone.now + 1.hour }

      context '販売承認済みの場合' do
        let(:sales_status) { :on_sale }

        it '販売中の販売進捗ステータスが返ること' do
          expect(sales_progress).to eq :on_sale
        end
      end

      context '販売未承認の場合' do
        let(:sales_status) { :before_sale }

        it '販売未承認の販売進捗ステータスが返ること' do
          expect(sales_progress).to eq :unapproved_sale
        end
      end

      context '販売中止の場合' do
        let(:sales_status) { :discontinued }

        it '販売中止の販売進捗ステータスが返ること' do
          expect(sales_progress).to eq :discontinued
        end
      end
    end
  end

  describe '#admission_progress' do
    subject(:admission_progress) { seat_sale.admission_progress }

    let(:seat_sale) { create(:seat_sale, :available, admission_available_at: admission_available_at, admission_close_at: admission_close_at) }

    context '(前, 前) 入場開始時間より前、入場終了時間より前' do
      let(:admission_available_at) { Time.zone.now + 1.hour }
      let(:admission_close_at) { Time.zone.now + 2.hours }

      it '開場前の入退場進捗ステータスが返ること' do
        expect(admission_progress).to eq :not_started
      end
    end

    context '(後, 後) 入場開始時間より後、入場終了時間より後' do
      let(:admission_available_at) { Time.zone.now - 2.hours }
      let(:admission_close_at) { Time.zone.now - 1.hour }

      it '退場済みの入退場進捗ステータスが返ること' do
        expect(admission_progress).to eq :finished
      end
    end

    context '(後, 前) 入場開始時間より後、入場終了時間より前' do
      let(:admission_available_at) { Time.zone.now - 1.hour }
      let(:admission_close_at) { Time.zone.now + 1.hour }

      it '入場中の入退場進捗ステータスが返ること' do
        expect(admission_progress).to eq :in_progress
      end
    end
  end
end

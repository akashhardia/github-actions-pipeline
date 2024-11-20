# frozen_string_literal: true

# == Schema Information
#
# Table name: template_seat_sales
#
#  id          :bigint           not null, primary key
#  description :string(255)
#  immutable   :boolean          default(FALSE), not null
#  status      :integer          default("available"), not null
#  title       :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe TemplateSeatSale, type: :model do
  describe 'validationの確認' do
    it 'titleがなければerrorになること' do
      template_seat_sale = described_class.new
      expect(template_seat_sale.valid?).to eq false
    end
  end

  describe '#template_immutable?' do
    subject(:template_immutable?) { template_seat_sale.template_immutable? }

    let(:template_seat_sale) { create(:template_seat_sale, immutable: immutable) }
    let(:immutable) { false }

    context '変更不可属性がついている場合' do
      let(:immutable) { true }

      it 'trueであること' do
        expect(template_immutable?).to be true
      end
    end

    context 'テンプレートが販売実績のある販売情報と紐付いている場合' do
      before do
        create(:seat_sale, template_seat_sale: template_seat_sale, sales_start_at: Time.zone.now - 1.hour, sales_status: :on_sale)
      end

      it 'trueであること' do
        expect(template_immutable?).to be true
      end
    end

    context 'テンプレートが自動生成値モデルと紐付いている場合' do
      before do
        create(:template_seat_sale_schedule, template_seat_sale: template_seat_sale)
      end

      it 'trueであること' do
        expect(template_immutable?).to be true
      end
    end

    context 'テンプレートが販売実績のある販売情報と紐付いていない場合' do
      before do
        create(:seat_sale, template_seat_sale: template_seat_sale, sales_start_at: Time.zone.now + 1.hour, sales_status: :on_sale)
      end

      it 'falseであること' do
        expect(template_immutable?).to be false
      end
    end
  end

  describe '#template_already_on_sale?' do
    subject(:template_already_on_sale?) { template_seat_sale.template_already_on_sale? }

    let(:template_seat_sale) { create(:template_seat_sale) }

    context 'テンプレートが販売実績のある販売情報と紐付いている場合' do
      before do
        create(:seat_sale, template_seat_sale: template_seat_sale, sales_start_at: Time.zone.now - 1.hour, sales_status: :on_sale)
      end

      it 'trueであること' do
        expect(template_already_on_sale?).to be true
      end
    end

    context 'テンプレートが自動生成値モデルと紐付いている場合' do
      before do
        create(:template_seat_sale_schedule, template_seat_sale: template_seat_sale)
      end

      it 'trueであること' do
        expect(template_already_on_sale?).to be true
      end
    end

    context 'テンプレートが販売実績のある販売情報と紐付いていない場合' do
      before do
        create(:seat_sale, template_seat_sale: template_seat_sale, sales_start_at: Time.zone.now + 1.hour, sales_status: :on_sale)
      end

      it 'falseであること' do
        expect(template_already_on_sale?).to be false
      end
    end
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: template_seat_type_options
#
#  id                    :bigint           not null, primary key
#  companion             :boolean          default(FALSE), not null
#  description           :string(255)
#  price                 :integer          not null
#  title                 :string(255)      not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  template_seat_type_id :bigint           not null
#
# Indexes
#
#  index_template_seat_type_options_on_template_seat_type_id  (template_seat_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (template_seat_type_id => template_seat_types.id)
#
require 'rails_helper'

RSpec.describe TemplateSeatTypeOption, type: :model do
  describe 'validationの確認' do
    let(:template_seat_type) { create(:template_seat_type, price: 10_000) }

    it 'priceがなければerrorになること' do
      template_seat_type_option = described_class.new(title: 'option', template_seat_type: template_seat_type)
      expect(template_seat_type_option.valid?).to eq false
    end

    it 'titleがなければerrorになること' do
      template_seat_type_option = described_class.new(price: -5_000, template_seat_type: template_seat_type)
      expect(template_seat_type_option.valid?).to eq false
    end

    it 'template_seat_typeがなければerrorになること' do
      template_seat_type_option = described_class.new(price: -5_000, title: 'option')
      expect(template_seat_type_option.valid?).to eq false
    end

    context 'priceのvalidate確認' do
      it 'priceが文字の場合' do
        result = described_class.new({ template_seat_type: template_seat_type, title: 'test', price: 'テスト' }).save
        expect(result).to eq false
      end

      it 'priceがintegerではない場合' do
        result = described_class.new({ template_seat_type: template_seat_type, title: 'test', price: -1000.5 }).save
        expect(result).to eq false
      end
    end

    context '座席単位が単体の場合' do
      it 'オプションの価格が基本価格を上回らない場合' do
        result = described_class.new({ template_seat_type: template_seat_type, title: 'test', price: -5_000 }).save
        expect(result).to eq true
      end

      it 'オプションの価格が基本価格を上回る場合' do
        template_seat_type_option = described_class.new({ template_seat_type: template_seat_type, title: 'test', price: -15_000 })
        expect(template_seat_type_option.valid?).to eq false
        expect(template_seat_type_option.errors.messages[:price]).to eq(['最小価格が0を下回っています'])
      end
    end

    context 'チケット単位がVIP・BOXの場合' do
      subject(:template_seat_type_option) { described_class.new({ template_seat_type: template_unit_seat_type, title: 'test', price: price }) }

      before do
        master_seats1.each do |master_seat|
          create(:template_seat, template_seat_type: template_unit_seat_type, master_seat: master_seat)
        end
      end

      let(:master_seat_unit1) { create(:master_seat_unit) }
      let(:master_seats1) { create_list(:master_seat, 3, master_seat_unit: master_seat_unit1) }
      let(:template_unit_seat_type) { create(:template_seat_type, price: 15_000) }

      context 'BOX席の合計割引額が基本価格を上回らない場合' do
        let(:price) { -5_000 }

        it 'trueであること' do
          expect(template_seat_type_option.valid?).to be true
        end
      end

      context 'BOX席の合計割引額が基本価格を上回る場合' do
        let(:price) { -5_500 }

        it 'falseであること' do
          expect(template_seat_type_option.valid?).to be false
          expect(template_seat_type_option.errors.messages[:price]).to eq(['最小価格が0を下回っています'])
        end
      end

      context '2つ目のBOX席の合計割引額が基本価格を上回る場合' do
        before do
          master_seats2.each do |master_seat|
            create(:template_seat, template_seat_type: template_unit_seat_type, master_seat: master_seat)
          end
        end

        let(:master_seat_unit2) { create(:master_seat_unit) }
        let(:master_seats2) { create_list(:master_seat, 4, master_seat_unit: master_seat_unit2) }

        let(:price) { -5_000 }

        it 'falseであること' do
          expect(template_seat_type_option.valid?).to be false
          expect(template_seat_type_option.errors.messages[:price]).to eq(['最小価格が0を下回っています'])
        end
      end
    end
  end
end

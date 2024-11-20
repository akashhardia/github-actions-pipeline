# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TemplateDuplicator, type: :model do
  let!(:origin_template_seat_sale) { create(:template_seat_sale) }
  let!(:origin_template_seat_type_1) { create(:template_seat_type, template_seat_sale: origin_template_seat_sale, price: 3000) }
  let!(:origin_template_seat_type_2) { create(:template_seat_type, template_seat_sale: origin_template_seat_sale, price: 5000) }
  let!(:origin_template_seat_area) { create(:template_seat_area, template_seat_sale: origin_template_seat_sale) }

  let(:new_template_seat_sale_params) do
    {
      id: origin_template_seat_sale.id,
      title: 'new_title',
      description: 'new_description'
    }
  end

  before do
    create_list(:template_seat, 10, template_seat_type: origin_template_seat_type_1, template_seat_area: origin_template_seat_area, status: rand(0..1))
    create(:template_seat_type_option, template_seat_type: origin_template_seat_type_1, title: 'U-19', price: -2000)
    create(:template_seat_type_option, template_seat_type: origin_template_seat_type_1, title: 'U-12', price: -1000)
    create(:template_seat_type_option, template_seat_type: origin_template_seat_type_2, title: 'U-19', price: -1500)
    create(:template_seat_type_option, template_seat_type: origin_template_seat_type_2, title: 'U-12', price: -500)
  end

  describe 'TemplateSeatSaleコピー' do
    subject(:duplicate_template_seat_sale!) do
      template_duplicator = described_class.new(new_template_seat_sale_params)
      template_duplicator.send(:duplicate_template_seat_sale!)
    end

    it 'TemplateSeatSaleのレコード数が1つ増える' do
      expect { duplicate_template_seat_sale! }.to change(TemplateSeatSale, :count).by(1)
    end

    it '作成されたTemplateSeatSaleの属性がコピー元と一致していること' do
      duplicate_template_seat_sale!
      expect_attributes = {
        title: origin_template_seat_sale.title,
        description: origin_template_seat_sale.description
      }
      expect(TemplateSeatSale.exists?(expect_attributes)).to be true
    end
  end

  describe 'TemplateSeatTypeコピー' do
    subject(:duplicate_template_seat_types!) do
      template_duplicator = described_class.new(new_template_seat_sale_params)
      new_template_seat_sale = template_duplicator.send(:duplicate_template_seat_sale!)
      template_duplicator.send(:duplicate_template_seat_types!, new_template_seat_sale)
    end

    it 'コピー元のTemplateSeatTypeと同数のレコードが追加されていること' do
      origin_template_seat_types = origin_template_seat_sale.template_seat_types
      expect { duplicate_template_seat_types! }.to change(TemplateSeatType, :count).by(origin_template_seat_types.count)
    end

    it '作成されたTemplateSeatTypeのレコード内容がコピー元と一致していること' do
      # コピー元のTemplateSeatType
      origin_template_seat_types = origin_template_seat_sale.template_seat_types
      # 作成されたTemplateSeatType
      duplicate_template_seat_types!
      new_template_seat_sale = TemplateSeatSale.last
      new_template_seat_types = new_template_seat_sale.template_seat_types
      # 作成されたTemplateSeatTypeを1つずつレコード内容をコピー元と比較する
      new_template_seat_types.each do |new_template_seat_type|
        origin_template_seat_type = origin_template_seat_types.find_by(master_seat_type_id: new_template_seat_type.master_seat_type_id)
        expect(new_template_seat_type).to have_attributes(price: origin_template_seat_type.price)
      end
    end
  end

  describe 'TemplateSeatAreaコピー' do
    subject(:duplicate_template_seat_areas) do
      template_duplicator = described_class.new(new_template_seat_sale_params)
      new_template_seat_sale = template_duplicator.send(:duplicate_template_seat_sale!)
      template_duplicator.send(:duplicate_template_seat_areas!, new_template_seat_sale)
    end

    it 'コピー元のTemplateSeatAreaと同数のレコードが追加されていること' do
      origin_template_seat_areas = origin_template_seat_sale.template_seat_areas
      expect { duplicate_template_seat_areas }.to change(TemplateSeatArea, :count).by(origin_template_seat_areas.count)
    end

    it '作成されたTemplateSeatAreaのレコード内容がコピー元と一致していること' do
      # コピー元のTemplateSeatArea
      origin_template_seat_areas = origin_template_seat_sale.template_seat_areas
      # 作成されたTemplateSeatArea
      duplicate_template_seat_areas
      new_template_seat_sale = TemplateSeatSale.last
      new_template_seat_areas = new_template_seat_sale.template_seat_areas
      # 作成されたTemplateSeatAreaを1つずつレコード内容をコピー元と比較する
      new_template_seat_areas.each do |new_template_seat_area|
        origin_template_seat_area = origin_template_seat_areas.find_by(master_seat_area_id: new_template_seat_area.master_seat_area_id)
        expect(new_template_seat_area).to have_attributes(displayable: origin_template_seat_area.displayable)
      end
    end
  end

  describe 'TemplateSeatTypeOptionコピー' do
    subject(:duplicate_template_seat_type_options) do
      template_duplicator = described_class.new(new_template_seat_sale_params)
      new_template_seat_sale = template_duplicator.send(:duplicate_template_seat_sale!)
      template_duplicator.send(:duplicate_template_seat_types!, new_template_seat_sale)
      template_duplicator.send(:duplicate_template_seat_type_options!, new_template_seat_sale)
    end

    it 'コピー元のTemplateSeatTypeOptionと同数のレコードが追加されていること' do
      origin_template_seat_sale_including_options = TemplateSeatSale.includes(template_seat_types: :template_seat_type_options).find(origin_template_seat_sale.id)
      origin_template_seat_type_options = origin_template_seat_sale_including_options.template_seat_types.map(&:template_seat_type_options).flatten
      expect { duplicate_template_seat_type_options }.to change(TemplateSeatTypeOption, :count).by(origin_template_seat_type_options.count)
    end

    it '作成されたTemplateSeatTypeOptionのレコード内容がコピー元と一致していること' do
      # コピー元のTemplateSeatTypeOption
      origin_template_seat_types = origin_template_seat_sale.template_seat_types
      # 作成されたTemplateSeatTypeOption
      duplicate_template_seat_type_options
      new_template_seat_sale = TemplateSeatSale.last
      new_template_seat_types = new_template_seat_sale.template_seat_types
      # 作成されたTemplateSeatTypeOptionを1つずつレコード内容をコピー元と比較する
      new_template_seat_types.each do |new_template_seat_type|
        origin_template_seat_type = origin_template_seat_types.find_by(master_seat_type_id: new_template_seat_type.master_seat_type_id)
        origin_template_seat_type_options = origin_template_seat_type.template_seat_type_options
        new_template_seat_type_options = new_template_seat_type.template_seat_type_options
        new_template_seat_type_options.each do |new_template_seat_type_option|
          origin_template_seat_type_option = origin_template_seat_type_options.find_by(title: new_template_seat_type_option.title)
          expect(new_template_seat_type_option).to have_attributes(price: origin_template_seat_type_option.price)
        end
      end
    end
  end

  describe 'TemplateSeatコピー' do
    subject(:duplicate_template_seats!) do
      template_duplicator = described_class.new(new_template_seat_sale_params)
      new_template_seat_sale = template_duplicator.send(:duplicate_template_seat_sale!)
      template_duplicator.send(:duplicate_template_seat_types!, new_template_seat_sale)
      template_duplicator.send(:duplicate_template_seat_areas!, new_template_seat_sale)
      template_duplicator.send(:duplicate_template_seats!, new_template_seat_sale)
    end

    it 'コピー元のTemplateSeatと同数のレコードが追加されていること' do
      origin_template_seats = origin_template_seat_sale.template_seats
      expect { duplicate_template_seats! }.to change(TemplateSeat, :count).by(origin_template_seats.count)
    end

    it '作成されたTemplateSeatのレコード内容がコピー元と一致していること' do
      # コピー元のTemplateSeat
      origin_template_seats = origin_template_seat_sale.template_seats
      # 作成されたTemplateSeatType
      duplicate_template_seats!
      new_template_seat_sale = TemplateSeatSale.last
      new_template_seat_seats = new_template_seat_sale.template_seats
      # 作成されたTemplateSeatを1つずつレコード内容をコピー元と比較する
      new_template_seat_seats.each do |new_template_seat|
        origin_template_seat = origin_template_seats.find { |s| s.master_seat_id == new_template_seat.master_seat_id }
        expect(new_template_seat).to have_attributes(status: origin_template_seat.status)
      end
    end
  end

  describe 'duplicate_all_templates!' do
    subject(:duplicate_all_templates) do
      template_duplicator = described_class.new(new_template_seat_sale_params)
      template_duplicator.duplicate_all_templates!
    end

    it '正常に終了すること' do
      expect { duplicate_all_templates }.not_to raise_error
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketsCreator, type: :model do
  let(:hold_daily_schedule) { create(:hold_daily_schedule) }
  let(:template_seat_sale) { create(:template_seat_sale) }
  let(:template_seat_area) { create(:template_seat_area, template_seat_sale: template_seat_sale) }
  let(:template_seat_type) { create(:template_seat_type, template_seat_sale: template_seat_sale) }
  let(:seat_sale) { create(:seat_sale, hold_daily_schedule: hold_daily_schedule) }
  let(:sales_start_at) { Time.zone.now }
  let(:sales_end_at) { Time.zone.now + 5.days }
  let(:admission_available_at) { Time.zone.now + 6.days }
  let(:admission_close_at) { admission_available_at + 6.hours }
  let(:tickets_params) do
    {
      hold_daily_schedule_id: hold_daily_schedule.id,
      template_seat_sale_id: template_seat_sale.id,
      sales_start_at: sales_start_at,
      sales_end_at: sales_end_at,
      admission_available_at: admission_available_at,
      admission_close_at: admission_close_at
    }
  end

  before do
    10.times do
      create(:master_seat, master_seat_area: template_seat_area.master_seat_area, master_seat_type: template_seat_type.master_seat_type)
      create(:template_seat, template_seat_area: template_seat_area, template_seat_type: template_seat_type)
    end
  end

  describe 'SeatSale作成' do
    subject(:create_seat_sale) do
      ticket_creator = described_class.new(tickets_params)
      ticket_creator.send(:create_seat_sale!)
    end

    it 'SeatSaleが作成されていること' do
      create_seat_sale
      expect_attributes = {
        template_seat_sale: template_seat_sale,
        hold_daily_schedule: hold_daily_schedule,
        sales_start_at: sales_start_at,
        sales_end_at: sales_end_at,
        admission_available_at: admission_available_at
      }

      expect(SeatSale.exists?(expect_attributes)).to be true
    end
  end

  describe 'SeatType作成' do
    subject(:create_seat_types) do
      ticket_creator = described_class.new(tickets_params)
      ticket_creator.send(:create_seat_types!, seat_sale)
    end

    it 'SeatTypeがTemplateSeatTypeと同じレコード数であること' do
      create_seat_types
      expect(TemplateSeatType.where(template_seat_sale: template_seat_sale.id).size).to eq(SeatType.all.size)
    end

    it 'SeatTypeとTemplateSeatTypeのレコード内容が同じであること' do
      create_seat_types
      TemplateSeatType.where(template_seat_sale_id: TemplateSeatSale.first.id).each do |template_seat_type|
        seat_type = SeatType.where(master_seat_type_id: template_seat_type.master_seat_type_id,
                                   template_seat_type: template_seat_type)
        expect(seat_type.size).to eq 1
      end
    end

    context '席種が未定義の場合' do
      let(:template_seat_type) { create(:template_seat_type) }

      it 'エラーが発生すること' do
        expect { create_seat_types }.to raise_error(CustomError, 'テンプレートに不備があります。席種が未定義です。')
      end
    end
  end

  describe 'SeatArea作成' do
    subject(:create_seat_areas) do
      ticket_creator = described_class.new(tickets_params)
      ticket_creator.send(:create_seat_areas!, seat_sale)
    end

    it 'SeatAreaがTemplateSeatAreaと同じレコード数であること' do
      create_seat_areas
      expect(TemplateSeatArea.where(template_seat_sale: template_seat_sale).size).to eq(SeatArea.all.size)
    end

    it 'SeatAreaとTemplateSeatAreaのレコード内容が同じであること' do
      create_seat_areas
      TemplateSeatArea.where(template_seat_sale: template_seat_sale).each do |template_seat_area|
        seat_areas = SeatArea.where(master_seat_area_id: template_seat_area.master_seat_area_id)
        expect(seat_areas.size).to eq 1
      end
    end

    context 'エリアが未定義の場合' do
      let(:template_seat_area) { create(:template_seat_area) }

      it 'エラーが発生すること' do
        expect { create_seat_areas }.to raise_error(CustomError, 'テンプレートに不備があります。エリアが未定義です。')
      end
    end
  end

  describe 'Ticket作成' do
    subject(:create_tickets!) do
      ticket_creator = described_class.new(tickets_params)
      ticket_creator.send(:create_seat_types!, seat_sale)
      ticket_creator.send(:create_seat_areas!, seat_sale)
      ticket_creator.send(:create_tickets!, seat_sale)
    end

    it 'TemplateSeatがTicketと同じレコード数であること' do
      create_tickets!
      expect(template_seat_sale.template_seats.size).to eq(Ticket.all.size)
    end

    it 'TemplateSeatとTicketのレコード内容が同じであること' do
      create_tickets!
      template_seat_sale.template_seats.all.each do |template_seat|
        ticket = Ticket.where(row: template_seat.row,
                              seat_number: template_seat.seat_number,
                              status: template_seat.status,
                              sales_type: template_seat.sales_type)
        expect(ticket.size).to eq 1

        expect(ticket.first.area_code == template_seat.template_seat_area.master_seat_area.area_code).to be true
        expect(ticket.first.name == template_seat.name).to be true
      end
    end
  end

  describe 'SeatTypeOption作成' do
    subject(:create_seat_type_options!) do
      ticket_creator = described_class.new(tickets_params)
      ticket_creator.send(:create_seat_types!, seat_sale)
      ticket_creator.send(:create_seat_type_options!, seat_sale)
    end

    before do
      create(:template_seat_type_option, template_seat_type: template_seat_type)
    end

    it 'TemplateSeatTypeOptionがSeatTypeOptionと同じレコード数であること' do
      create_seat_type_options!
      expect(template_seat_sale.template_seat_type_options.size == SeatTypeOption.all.size).to be true
    end

    it 'TemplateSeatTypeOptionとSeatTypeOptionのレコード内容が同じであること' do
      create_seat_type_options!
      TemplateSeatSale.first.template_seat_type_options.each do |template_seat_type_option|
        seat_type = SeatType.where(master_seat_type_id: template_seat_type_option.template_seat_type.master_seat_type_id,
                                   template_seat_type: template_seat_type_option.template_seat_type)
        expect(seat_type.size).to eq 1
        seat_type_option = seat_type.first.seat_type_options.where(template_seat_type_option: template_seat_type_option)
        expect(seat_type_option.size).to eq 1
        expect(seat_type_option.first.seat_type.name == template_seat_type_option.template_seat_type.name).to be true
      end
    end
  end
end

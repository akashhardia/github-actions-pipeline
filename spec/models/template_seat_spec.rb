# frozen_string_literal: true

# == Schema Information
#
# Table name: template_seats
#
#  id                    :bigint           not null, primary key
#  status                :integer          default("available"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  master_seat_id        :bigint           not null
#  template_seat_area_id :bigint           not null
#  template_seat_type_id :bigint           not null
#
# Indexes
#
#  index_template_seats_on_master_seat_id         (master_seat_id)
#  index_template_seats_on_template_seat_area_id  (template_seat_area_id)
#  index_template_seats_on_template_seat_type_id  (template_seat_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (master_seat_id => master_seats.id)
#  fk_rails_...  (template_seat_area_id => template_seat_areas.id)
#  fk_rails_...  (template_seat_type_id => template_seat_types.id)
#
require 'rails_helper'

RSpec.describe TemplateSeat, type: :model do
  describe 'validationの確認' do
    let(:master_seat) { create(:master_seat) }
    let(:template_seat_area) { create(:template_seat_area) }
    let(:template_seat_type) { create(:template_seat_type) }

    it 'master_seatがなければerrorになること' do
      template_seat = described_class.new(template_seat_type: template_seat_type, template_seat_area: template_seat_area)
      expect(template_seat.valid?).to eq false
    end

    it 'template_seat_areaがなければerrorになること' do
      template_seat = described_class.new(master_seat: master_seat, template_seat_type: template_seat_type)
      expect(template_seat.valid?).to eq false
    end

    it 'template_seat_typeがなければerrorになること' do
      template_seat = described_class.new(master_seat: master_seat, template_seat_area: template_seat_area)
      expect(template_seat.valid?).to eq false
    end
  end

  describe '#stop_selling!' do
    subject(:stop_selling!) { template_seat.stop_selling! }

    let(:template_seat) { create(:template_seat, status: :available, template_seat_type: template_seat_type) }
    let(:template_seat_type) { create(:template_seat_type, template_seat_sale: template_seat_sale) }
    let(:template_seat_sale) { create(:template_seat_sale) }

    context 'シートのステータスが販売可能である場合' do
      it 'ステータスが仮押さえに変更されること' do
        expect { stop_selling! }.to change(template_seat, :status).from('available').to('not_for_sale')
      end
    end

    context 'テンプレートが変更不可である場合' do
      let(:template_seat_sale) { create(:template_seat_sale, immutable: true) }

      it 'エラーが発生すること' do
        expect { stop_selling! }.to raise_error(ApiBadRequestError, I18n.t('custom_errors.template.template_is_immutable'))
      end
    end
  end

  describe '#release_from_stop_selling!' do
    subject(:release_from_stop_selling!) { template_seat.release_from_stop_selling! }

    let(:template_seat) { create(:template_seat, status: :not_for_sale, template_seat_type: template_seat_type) }
    let(:template_seat_type) { create(:template_seat_type, template_seat_sale: template_seat_sale) }
    let(:template_seat_sale) { create(:template_seat_sale) }

    context 'シートのステータスが販売可能である場合' do
      it 'ステータスが仮押さえに変更されること' do
        expect { release_from_stop_selling! }.to change(template_seat, :status).from('not_for_sale').to('available')
      end
    end

    context 'テンプレートが変更不可である場合' do
      let(:template_seat_sale) { create(:template_seat_sale, immutable: true) }

      it 'エラーが発生すること' do
        expect { release_from_stop_selling! }.to raise_error(ApiBadRequestError, I18n.t('custom_errors.template.template_is_immutable'))
      end
    end
  end
end

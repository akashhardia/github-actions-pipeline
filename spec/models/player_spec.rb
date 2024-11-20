# frozen_string_literal: true

# == Schema Information
#
# Table name: players
#
#  id                :bigint           not null, primary key
#  area_code         :string(255)
#  birthday          :date
#  catchphrase       :string(255)
#  chest             :decimal(4, 1)
#  country_code      :string(255)
#  current_rank_code :string(255)
#  dash              :decimal(4, 2)
#  delete_day        :date
#  duration          :decimal(4, 2)
#  gender_code       :integer
#  graduate          :integer
#  height            :decimal(4, 1)
#  keirin_delete     :date
#  keirin_expiration :date
#  keirin_regist     :date
#  keirin_update     :date
#  lap_1000          :string(255)
#  lap_200           :string(255)
#  lap_400           :string(255)
#  leftgrip          :decimal(3, 1)
#  max_speed         :decimal(4, 2)
#  middle_delete     :date
#  middle_expiration :date
#  middle_regist     :date
#  middle_update     :date
#  name_en           :string(255)
#  name_jp           :string(255)
#  next_rank_code    :string(255)
#  player_class      :integer
#  regist_day        :date
#  regist_num        :integer
#  rightgrip         :decimal(3, 1)
#  spine             :decimal(5, 1)
#  thigh             :decimal(4, 1)
#  vital             :decimal(5, 1)
#  weight            :decimal(4, 1)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  pf_player_id      :string(255)
#
# Indexes
#
#  index_players_on_pf_player_id  (pf_player_id)
#
require 'rails_helper'

RSpec.describe Player, type: :model do
  describe 'evaluation_range' do
    subject(:evaluation_range) { player.send(:evaluation_range, value) }

    let(:player) { described_class.new(player_class: 1, regist_num: 1, pf_player_id: 1) }

    let(:value) { nil }

    context 'valueを指定しない場合' do
      it 'nilが返ってくること' do
        expect(evaluation_range).to eq(nil)
      end
    end

    context 'valueが57を指定した場合' do
      let(:value) { 57 }

      it '範囲に一致する値が返ってくること' do
        expect(evaluation_range).to eq(:C)
      end
    end

    context 'valueが69を指定した場合' do
      let(:value) { 69 }

      it '範囲に一致する値が返ってくること' do
        expect(evaluation_range).to eq(:B)
      end
    end

    context 'valueが81を指定した場合' do
      let(:value) { 81 }

      it '範囲に一致する値が返ってくること' do
        expect(evaluation_range).to eq(:A)
      end
    end

    context 'valueが89を指定した場合' do
      let(:value) { 89 }

      it '範囲に一致する値が返ってくること' do
        expect(evaluation_range).to eq(:S)
      end
    end

    context 'valueが90を指定した場合' do
      let(:value) { 90 }

      it '範囲に一致する値が返ってくること' do
        expect(evaluation_range).to eq(:SS)
      end
    end

    context 'valueが101を指定した場合' do
      let(:value) { 101 }

      it 'nilが返ってくること' do
        expect(evaluation_range).to eq(nil)
      end
    end
  end

  describe 'evaluation_select' do
    subject(:evaluation_select) { described_class.evaluation_select(evaluation) }

    let(:evaluation) { nil }

    context 'evaluationが50だった場合' do
      let(:evaluation) { 50 }

      it '範囲に一致する値が返ってくること' do
        expect(evaluation_select).to eq(:C)
      end
    end

    context 'evaluationが60だった場合' do
      let(:evaluation) { 60 }

      it '範囲に一致する値が返ってくること' do
        expect(evaluation_select).to eq(:B)
      end
    end

    context 'evaluationが75だった場合' do
      let(:evaluation) { 75 }

      it '範囲に一致する値が返ってくること' do
        expect(evaluation_select).to eq(:A)
      end
    end

    context 'evaluationが85だった場合' do
      let(:evaluation) { 85 }

      it '範囲に一致する値が返ってくること' do
        expect(evaluation_select).to eq(:S)
      end
    end

    context 'evaluationが90だった場合' do
      let(:evaluation) { 90 }

      it '範囲に一致する値が返ってくること' do
        expect(evaluation_select).to eq(:SS)
      end
    end
  end
end

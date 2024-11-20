# frozen_string_literal: true

require 'rails_helper'

describe OrderValidator, type: :model do
  describe '#validate' do
    subject(:validation) do
      order_validator = described_class.new(orders, coupon_id, campaign_code, user1)
      order_validator.validation_error
    end

    let(:user1) { create(:user) }

    context '有効なオーダーだった場合' do
      let(:seat_sale) { create(:seat_sale, :available) }
      let(:seat_type1) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_type2) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
      let(:ticket1) { create(:ticket, seat_type: seat_type1, seat_area: seat_area) }
      let(:ticket2) { create(:ticket, seat_type: seat_type1, seat_area: seat_area) }
      let(:ticket3) { create(:ticket, seat_type: seat_type2, seat_area: seat_area) }
      let(:ticket4) { create(:ticket, seat_type: seat_type2, seat_area: seat_area) }

      let(:seat_type_option1) { create(:seat_type_option, seat_type: seat_type1) }
      let(:seat_type_option2) { create(:seat_type_option, seat_type: seat_type2) }

      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: seat_type_option2.id },
          { ticket_id: ticket4.id, option_id: nil }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      it 'バリデーションが通ること' do
        expect(validation).to be nil
      end
    end

    context '存在しないチケットが含まれて居た場合' do
      let(:seat_sale) { create(:seat_sale, :available) }
      let(:seat_type1) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_type2) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
      let(:ticket1) { create(:ticket, seat_type: seat_type1, seat_area: seat_area) }
      let(:ticket2) { create(:ticket, seat_type: seat_type1, seat_area: seat_area) }

      let(:seat_type_option1) { create(:seat_type_option, seat_type: seat_type1) }
      let(:seat_type_option2) { create(:seat_type_option, seat_type: seat_type2) }

      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: -1, option_id: nil }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      it 'バリデーションに検知されること' do
        expect(validation).to eq(:ticket_not_found)
      end
    end

    context 'ordersが空の場合' do
      let(:orders) { [] }
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      it 'バリデーションに検知されること' do
        expect(validation).to eq(:cart_is_empty)
      end
    end

    context '販売マスターの販売ステータスが販売中ではなかった場合' do
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
      let(:ticket) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }
      let(:orders) do
        [
          { ticket_id: ticket.id, option_id: nil },
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      context 'before_sale' do
        let(:seat_sale) { create(:seat_sale, sales_status: :before_sale) }

        it 'バリデーションに検知されること' do
          expect(validation).to eq(:unapproved_sales)
        end
      end

      context 'discontinued' do
        let(:seat_sale) { create(:seat_sale, sales_status: :discontinued) }

        it 'バリデーションに検知されること' do
          expect(validation).to eq(:unapproved_sales)
        end
      end
    end

    context 'エリアが非販売エリアだった場合' do
      let(:seat_sale) { create(:seat_sale, :available) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale, displayable: false) }
      let(:ticket) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }
      let(:orders) do
        [
          { ticket_id: ticket.id, option_id: nil },
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      it 'バリデーションに検知されること' do
        expect(validation).to eq(:unapproved_sales)
      end
    end

    context '販売期間外だった場合' do
      let(:seat_sale) { create(:seat_sale, :out_of_term, sales_status: :on_sale) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
      let(:ticket) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }

      let(:orders) do
        [
          { ticket_id: ticket.id, option_id: nil }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      it 'バリデーションに検知されること' do
        expect(validation).to eq(:sale_term_outside)
      end
    end

    context '購入可能でないステータスのチケットが含まれていた場合' do
      let(:seat_sale) { create(:seat_sale, :available) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
      let(:ticket1) { create(:ticket, seat_type: seat_type, seat_area: seat_area) }
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
          { ticket_id: ticket2.id, option_id: nil }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      context 'sold' do
        let(:ticket2) { create(:ticket, :sold, seat_type: seat_type, seat_area: seat_area) }

        it 'バリデーションに検知されること' do
          expect(validation).to eq(:ticket_not_available)
        end
      end

      context 'not_for_sale' do
        let(:ticket2) { create(:ticket, :not_for_sale, seat_type: seat_type) }

        it 'バリデーションに検知されること' do
          expect(validation).to eq(:ticket_not_available)
        end
      end

      context 'user_idがnil以外' do
        let(:ticket2) { create(:ticket, seat_type: seat_type, seat_area: seat_area, user_id: user1.id) }

        it 'バリデーションに検知されること' do
          expect(validation).to eq(:ticket_not_available)
        end
      end
    end

    context '異なるエリアのチケットが含まれていた場合' do
      let(:master_seat_area_a) { create(:master_seat_area, area_code: 'A') }
      let(:master_seat_area_b) { create(:master_seat_area, area_code: 'B') }
      let(:seat_area_a) { create(:seat_area, master_seat_area: master_seat_area_a) }
      let(:seat_area_b) { create(:seat_area, master_seat_area: master_seat_area_b) }

      let(:seat_sale) { create(:seat_sale, :available) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:ticket1) { create(:ticket, seat_type: seat_type, seat_area: seat_area_a) }
      let(:ticket2) { create(:ticket, seat_type: seat_type, seat_area: seat_area_b) }
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
          { ticket_id: ticket2.id, option_id: nil }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      it 'バリデーションに検知されること' do
        expect(validation).to eq(:seat_area_mismatch)
      end
    end

    context '販売マスターの異なるチケットが含まれていた場合' do
      let(:seat_sale1) { create(:seat_sale, :available) }
      let(:seat_sale2) { create(:seat_sale, :available) }
      let(:seat_type1) { create(:seat_type, seat_sale: seat_sale1) }
      let(:seat_type2) { create(:seat_type, seat_sale: seat_sale2) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale1) }
      let(:ticket1) { create(:ticket, seat_type: seat_type1, seat_area: seat_area) }
      let(:ticket2) { create(:ticket, seat_type: seat_type2, seat_area: seat_area) }
      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
          { ticket_id: ticket2.id, option_id: nil },
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      it 'バリデーションに検知されること' do
        expect(validation).to eq(:seat_sale_mismatch)
      end
    end

    context '単体販売のチケットを選択した時' do
      let(:seat_sale) { create(:seat_sale, :available) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }

      context '9席以上選択されていた場合' do
        let(:ticket1) { create(:ticket, seat_type: seat_type, sales_type: :single, seat_area: seat_area) }
        let(:ticket2) { create(:ticket, seat_type: seat_type, sales_type: :single, seat_area: seat_area) }
        let(:ticket3) { create(:ticket, seat_type: seat_type, sales_type: :single, seat_area: seat_area) }
        let(:ticket4) { create(:ticket, seat_type: seat_type, sales_type: :single, seat_area: seat_area) }
        let(:ticket5) { create(:ticket, seat_type: seat_type, sales_type: :single, seat_area: seat_area) }
        let(:ticket6) { create(:ticket, seat_type: seat_type, sales_type: :single, seat_area: seat_area) }
        let(:ticket7) { create(:ticket, seat_type: seat_type, sales_type: :single, seat_area: seat_area) }
        let(:ticket8) { create(:ticket, seat_type: seat_type, sales_type: :single, seat_area: seat_area) }
        let(:ticket9) { create(:ticket, seat_type: seat_type, sales_type: :single, seat_area: seat_area) }

        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil },
            { ticket_id: ticket4.id, option_id: nil },
            { ticket_id: ticket5.id, option_id: nil },
            { ticket_id: ticket6.id, option_id: nil },
            { ticket_id: ticket7.id, option_id: nil },
            { ticket_id: ticket8.id, option_id: nil },
            { ticket_id: ticket9.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { nil }

        it 'バリデーションに検知されること' do
          expect(validation).to eq(:exceed_purchase_limit)
        end
      end

      context '販売タイプが一致しない場合' do
        let(:ticket1) { create(:ticket, seat_type: seat_type, sales_type: :single, seat_area: seat_area) }
        let(:ticket2) { create(:ticket, seat_type: seat_type, sales_type: :single, seat_area: seat_area) }
        let(:ticket3) { create(:ticket, seat_type: seat_type, sales_type: :single, seat_area: seat_area) }
        let(:ticket4) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }

        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil },
            { ticket_id: ticket4.id, option_id: nil },
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { nil }

        it 'バリデーションに検知されること' do
          expect(validation).to eq(:sales_type_mismatch)
        end
      end
    end

    context 'Box販売のチケットを選択した時' do
      let(:seat_sale) { create(:seat_sale, :available) }
      let(:seat_sale2) { create(:seat_sale, :available) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_type2) { create(:seat_type, seat_sale: seat_sale2) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }

      let(:ticket1) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
      let(:ticket2) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
      let(:ticket3) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
      let(:ticket4) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
      let(:ticket5) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
      let(:ticket6) { create(:ticket, seat_type: seat_type2, sales_type: :unit, seat_area: seat_area) }

      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: nil },
          { ticket_id: ticket2.id, option_id: nil },
          { ticket_id: ticket3.id, option_id: nil },
          { ticket_id: ticket4.id, option_id: nil },
          { ticket_id: ticket5.id, option_id: nil }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      context '5席以上のBOX席の場合' do
        before do
          create(:master_seat_unit, tickets: [ticket1, ticket2, ticket3, ticket4, ticket5, ticket6])
        end

        let(:seat_sale) { create(:seat_sale, :available) }
        let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
        let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }

        let(:ticket1) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        let(:ticket2) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        let(:ticket3) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        let(:ticket4) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        let(:ticket5) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }

        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil },
            { ticket_id: ticket4.id, option_id: nil },
            { ticket_id: ticket5.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { nil }

        it '購入が可能なこと' do
          expect(validation).to be nil
        end
      end

      context 'Box販売しているチケットの数が合わない場合' do
        before do
          create(:master_seat_unit, tickets: [ticket1, ticket2, ticket3, ticket4, ticket5])
        end

        let(:seat_sale) { create(:seat_sale, :available) }
        let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
        let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }

        let(:ticket1) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        let(:ticket2) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        let(:ticket3) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        let(:ticket4) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        let(:ticket5) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }

        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil },
            { ticket_id: ticket5.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { nil }

        it 'バリデーションに検知されること' do
          expect(validation).to eq(:excess_or_deficiency_unit_ticket)
        end
      end

      context '販売タイプが一致しない場合' do
        before do
          create(:master_seat_unit, tickets: [ticket1, ticket2, ticket3, ticket4, ticket5])
        end

        let(:seat_sale) { create(:seat_sale, :available) }
        let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
        let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }

        let(:ticket1) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        let(:ticket2) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        let(:ticket3) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        let(:ticket4) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        # データ上ありえない想定だが一応
        let(:ticket5) { create(:ticket, seat_type: seat_type, sales_type: :single, seat_area: seat_area) }

        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket2.id, option_id: nil },
            { ticket_id: ticket3.id, option_id: nil },
            { ticket_id: ticket4.id, option_id: nil },
            { ticket_id: ticket5.id, option_id: nil }
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { nil }

        it 'バリデーションに検知されること' do
          expect(validation).to eq(:sales_type_mismatch)
        end
      end

      context '別ユニットのチケットが混ざっていた場合' do
        before do
          create(:master_seat_unit, tickets: [ticket1, ticket2])
          create(:master_seat_unit, tickets: [ticket3, ticket4])
        end

        let(:seat_sale) { create(:seat_sale, :available) }
        let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
        let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }

        let(:ticket1) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        let(:ticket2) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        let(:ticket3) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }
        let(:ticket4) { create(:ticket, seat_type: seat_type, sales_type: :unit, seat_area: seat_area) }

        let(:orders) do
          [
            { ticket_id: ticket1.id, option_id: nil },
            { ticket_id: ticket4.id, option_id: nil },
          ]
        end
        let(:coupon_id) { nil }
        let(:campaign_code) { nil }

        it 'バリデーションに検知されること' do
          expect(validation).to eq(:excess_or_deficiency_unit_ticket)
        end
      end
    end

    context 'チケットに対応しないオプションを選んだ場合' do
      let(:seat_sale) { create(:seat_sale, :available) }
      let(:seat_type1) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_type2) { create(:seat_type, seat_sale: seat_sale) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
      let(:ticket1) { create(:ticket, seat_type: seat_type1, seat_area: seat_area) }
      let(:ticket2) { create(:ticket, seat_type: seat_type1, seat_area: seat_area) }

      let(:seat_type_option1) { create(:seat_type_option, seat_type: seat_type1) }
      let(:seat_type_option2) { create(:seat_type_option, seat_type: seat_type2) }

      let(:orders) do
        [
          { ticket_id: ticket1.id, option_id: seat_type_option1.id },
          { ticket_id: ticket2.id, option_id: seat_type_option2.id }
        ]
      end
      let(:coupon_id) { nil }
      let(:campaign_code) { nil }

      it 'バリデーションに検知されること' do
        expect(validation).to eq(:seat_type_option_mismatch)
      end
    end

    describe 'クーポン適用時' do
      before do
        create(:user_coupon, user: user1, coupon: coupon)
        create(:coupon_hold_daily_condition, coupon: coupon, hold_daily_schedule: seat_sale.hold_daily_schedule)
        create(:coupon_seat_type_condition, coupon: coupon, master_seat_type: seat_type.master_seat_type)
      end

      let(:coupon) { create(:coupon) }
      let(:seat_sale) { create(:seat_sale, :available) }
      let(:seat_area) { create(:seat_area, seat_sale: seat_sale) }
      let(:seat_type) { create(:seat_type, seat_sale: seat_sale) }
      let(:ticket1) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
      let(:ticket2) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
      let(:ticket_id) { ticket.id }
      let(:seat_type_option) { create(:seat_type_option, seat_type: seat_type) }

      context '有効なクーポンを適応した時' do
        context 'オプションの指定が無い場合' do
          let(:orders) do
            [
              { ticket_id: ticket1.id, option_id: nil },
              { ticket_id: ticket2.id, option_id: nil }
            ]
          end
          let(:coupon_id) { coupon.id }
          let(:campaign_code) { nil }

          it 'バリデーションが通ること' do
            expect(validation).to be nil
          end
        end

        context 'オプションの指定がある場合' do
          let(:orders) do
            [
              { ticket_id: ticket1.id, option_id: seat_type_option.id },
              { ticket_id: ticket2.id, option_id: seat_type_option.id }
            ]
          end
          let(:coupon_id) { coupon.id }
          let(:campaign_code) { nil }

          it 'バリデーションに検知されること' do
            expect(validation).to eq(:option_and_coupon_cannot_be_used_at_same_time)
          end
        end
      end

      context '無効なクーポンを適応した時' do
        context 'userが持っていないクーポンを利用した場合' do
          let(:user_coupon) { create(:user_coupon, user: user_2, coupon: coupon_1) }
          # TODO: ログイン機能追加後はログインユーザー
          let!(:user_2) { create(:user) }
          let(:coupon) { create(:coupon) }
          let(:coupon_1) { create(:coupon) }
          let(:orders) do
            [
              { ticket_id: ticket1.id, option_id: nil },
              { ticket_id: ticket2.id, option_id: nil }
            ]
          end
          let(:coupon_id) { coupon_1.id }
          let(:campaign_code) { nil }

          it 'バリデーションに検知されること' do
            expect(validation).to eq(:coupon_not_found)
          end
        end

        context '利用終了日時を過ぎていた場合' do
          let(:coupon) { create(:coupon, available_end_at: Time.zone.now - rand(1..9).hour) }
          let(:orders) do
            [
              { ticket_id: ticket1.id, option_id: nil },
              { ticket_id: ticket2.id, option_id: nil }
            ]
          end
          let(:coupon_id) { coupon.id }
          let(:campaign_code) { nil }

          it 'バリデーションに検知されること' do
            expect(validation).to eq(:coupon_available_deadline_has_passed)
          end
        end

        context '対象の開催(hold_daily_schedule)で無い場合' do
          before do
            create(:seat_sale, :available)
          end

          let(:seat_sale_1) { create(:seat_sale, :available) }
          let(:seat_area) { create(:seat_area, seat_sale: seat_sale_1) }
          let(:seat_type) { create(:seat_type, seat_sale: seat_sale_1) }
          let(:ticket1) { create(:ticket, seat_area: seat_area, seat_type: seat_type) }
          let(:orders) do
            [
              { ticket_id: ticket1.id, option_id: nil },
              { ticket_id: ticket2.id, option_id: nil }
            ]
          end
          let(:coupon_id) { coupon.id }
          let(:campaign_code) { nil }

          it 'バリデーションに検知されること' do
            expect(validation).to eq(:coupon_hold_daily_schedules_mismatch)
          end
        end

        context '対象の席種(seat_type)で無い場合' do
          let(:seat_sale_1) { create(:seat_sale, :available) }
          let(:seat_type_1) { create(:seat_type, seat_sale: seat_sale_1) }
          let(:ticket1) { create(:ticket, seat_area: seat_area, seat_type: seat_type_1) }
          let(:orders) do
            [
              { ticket_id: ticket1.id, option_id: nil },
              { ticket_id: ticket2.id, option_id: nil }
            ]
          end
          let(:coupon_id) { coupon.id }
          let(:campaign_code) { nil }

          it 'バリデーションに検知されること' do
            expect(validation).to eq(:seat_sale_mismatch)
          end
        end
      end
    end
  end
end

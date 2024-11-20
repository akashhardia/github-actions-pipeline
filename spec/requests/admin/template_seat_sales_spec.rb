# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TemplateSeatSales', :admin_logged_in, type: :request do
  let(:valid_attributes) do
    {
      title: 'template_001',
      description: 'test_template_001'
    }
  end

  let(:invalid_attributes) do
    {
      name: 'aaa'
    }
  end

  describe 'GET /template_seat_sales' do
    subject(:template_seat_sale_index) { get admin_template_seat_sales_url(format: :json) }

    context 'HTTPステータスとレスポンスのjson属性について' do
      it 'renders a successful response' do
        TemplateSeatSale.create! valid_attributes
        get admin_template_seat_sales_url, as: :json
        expect(response).to be_successful
      end

      it 'jsonは::TemplateSeatSaleSerializerの属性を持つハッシュであること' do
        template_seat_sale_index
        json = JSON.parse(response.body)
        template_seat_sale_serializer_attributes = ::TemplateSeatSaleSerializer._attributes.map { |key| key.to_s.camelize(:lower) }
        template_seat_sale_serializer_attributes.append('masterSeatTypes')
        json['templateSeatSales'].all? { |hash| expect(hash.keys).to match_array(template_seat_sale_serializer_attributes) }
      end
    end

    context '承認待ち一覧のリクエストがある場合' do
      subject(:template_seat_sale_index) { get admin_template_seat_sales_url + '?type=before_sale' }

      before do
        create_list(:template_seat_sale, 10)
      end

      it '承認待ち一覧のみレスポンスとして返す' do
        template_seat_sale_index
        json = JSON.parse(response.body)
        expect(json['templateSeatSales'].size).to eq(10)
      end
    end

    context '販売中一覧のリクエストがある場合' do
      subject(:template_seat_sale_index) { get admin_template_seat_sales_url + '?type=on_sale' }

      before do
        create_list(:template_seat_sale, 10)
        create_list(:seat_sale, 5, :available)
      end

      it '販売中一覧のみレスポンスとして返す' do
        template_seat_sale_index
        json = JSON.parse(response.body)
        expect(json['templateSeatSales'].size).to eq(5)
      end
    end

    context 'すべてのクーポン一覧のリクエストがある場合' do
      before do
        create_list(:template_seat_sale, 8)
        create_list(:seat_sale, 2, :available)
      end

      it 'すべての販売テンプレートについてレスポンスとして返す' do
        template_seat_sale_index
        json = JSON.parse(response.body)
        expect(json['templateSeatSales'].size).to eq(10)
      end
    end

    context '利用数について' do
      let(:template_seat_sale) { create(:template_seat_sale) }

      before do
        create_list(:seat_sale, 5, template_seat_sale: template_seat_sale, sales_status: :on_sale)
        create_list(:seat_sale, 3, template_seat_sale: template_seat_sale, sales_status: :before_sale)
      end

      it '正常に取得することができる' do
        template_seat_sale_index
        json = JSON.parse(response.body)
        expect(json['templateSeatSales'][0]['numberOfUsed']).to eq(5)
      end
    end

    context 'paginationの設定で1ページ毎に表示する最大値を10としている場合' do
      before do
        create_list(:template_seat_sale, 20)
      end

      it '最大で返すクーポン数は10個(paginationを使っているため)' do
        template_seat_sale_index
        json = JSON.parse(response.body)
        expect(json['templateSeatSales'].size).to eq(10)
      end
    end
  end

  describe 'GET /template_seat_sale/:id' do
    it 'renders a successful response' do
      template_seat_sale = TemplateSeatSale.create! valid_attributes
      get admin_template_seat_sale_url(template_seat_sale), as: :json
      expect(response).to be_successful
    end

    # 期待する属性の配列
    template_seat_sale_serializer_attributes = %w[id title description immutable perSeatTypeSummaries status]

    it 'jsonは::TemplateSeatSaleSerializerの属性を持つハッシュであること' do
      template_seat_sale = TemplateSeatSale.create! valid_attributes
      get admin_template_seat_sale_url(template_seat_sale), as: :json
      json = JSON.parse(response.body)
      expect(json.keys).to match_array(template_seat_sale_serializer_attributes)
    end

    it 'テンプレートが削除されている場合' do
      template_seat_sale = TemplateSeatSale.create! valid_attributes
      template_seat_sale.unavailable!
      get admin_template_seat_sale_url(template_seat_sale), as: :json
      expect(response.body).to include 'ご指定の販売テンプレートは既に削除されています'
    end
  end

  describe 'GET /template_seat_sale/:id/edit ' do
    let(:immutable_attributes) do
      {
        title: 'template_001',
        description: 'test_template_001',
        immutable: true
      }
    end

    it 'renders a successful response' do
      template_seat_sale = TemplateSeatSale.create! valid_attributes
      get edit_admin_template_seat_sale_url(template_seat_sale), as: :json
      expect(response).to be_successful
    end

    # 期待する属性の配列
    template_seat_sale_serializer_attributes = %w[id title description immutable status]

    it 'jsonは::TemplateSeatSaleSerializerの属性を持つハッシュであること' do
      template_seat_sale = TemplateSeatSale.create! valid_attributes
      get edit_admin_template_seat_sale_url(template_seat_sale), as: :json
      json = JSON.parse(response.body)
      expect(json.keys).to match_array(template_seat_sale_serializer_attributes)
    end

    it 'テンプレートが削除されている場合' do
      template_seat_sale = TemplateSeatSale.create! valid_attributes
      template_seat_sale.unavailable!
      get edit_admin_template_seat_sale_url(template_seat_sale), as: :json
      expect(response.body).to include 'ご指定の販売テンプレートは既に削除されています'
    end

    it 'テンプレートが変更不可の場合' do
      template_seat_sale = TemplateSeatSale.create! immutable_attributes
      get edit_admin_template_seat_sale_url(template_seat_sale), as: :json
      expect(response.body).to include 'ご指定のテンプレートは削除変更不可対象または販売情報、自動生成に使用されているため変更できません'
    end
  end

  describe 'PATCH	/admin/template_seat_sales/:id' do
    subject(:update_template_seat_sale) do
      patch admin_template_seat_sale_url(init_template_seat_sale),
            params: new_attributes
    end

    let(:init_template_seat_sale) do
      create(:template_seat_sale,
             title: 'init_title',
             description: 'init_description')
    end

    let(:new_attributes) do
      {
        title: 'new_title',
        description: 'new_description'
      }
    end

    context '正しいパラメータが入力された場合、' do
      it 'レスポンスがOKであること' do
        update_template_seat_sale
        expect(response).to have_http_status(:ok)
      end

      it 'template_seat_saleのtitleが更新されていること' do
        expect { update_template_seat_sale }.to change {
          TemplateSeatSale.find(init_template_seat_sale.id).title
        }.from(init_template_seat_sale['title'])
          .to(new_attributes[:title])
      end
    end

    context '存在しないidの場合、' do
      let(:immutable_attributes) do
        {
          title: 'template_001',
          description: 'test_template_001',
          immutable: true
        }
      end

      it '404が返ること' do
        patch admin_template_seat_sale_url(9999), params: new_attributes
        expect(response).to have_http_status(:not_found)
      end

      it 'テンプレートが削除されている場合' do
        template_seat_sale = TemplateSeatSale.create! valid_attributes
        template_seat_sale.unavailable!
        patch admin_template_seat_sale_url(template_seat_sale), params: new_attributes
        expect(response.body).to include 'ご指定の販売テンプレートは既に削除されています'
      end

      it 'テンプレートが変更不可の場合' do
        template_seat_sale = TemplateSeatSale.create! immutable_attributes
        patch admin_template_seat_sale_url(template_seat_sale), params: new_attributes
        expect(response.body).to include 'ご指定のテンプレートは削除変更不可対象または販売情報、自動生成に使用されているため変更できません'
      end
    end
  end

  describe 'DELETE /template_seat_sale/:id' do
    it 'renders a successful response' do
      template_seat_sale = TemplateSeatSale.create! valid_attributes
      expect { delete admin_template_seat_sale_url(template_seat_sale), as: :json }.to change { TemplateSeatSale.find(template_seat_sale.id).status }.from('available').to('unavailable')
      expect(response).to be_successful
    end

    it '削除不可能の場合' do
      template_seat_sale = TemplateSeatSale.create! valid_attributes
      template_seat_sale.update!(immutable: true)
      delete admin_template_seat_sale_url(template_seat_sale), as: :json
      expect(response.body).to include 'ご指定のテンプレートは削除変更不可対象または販売情報、自動生成に使用されているため削除できません'
    end

    it 'テンプレートが無効の場合' do
      template_seat_sale = TemplateSeatSale.create! valid_attributes
      template_seat_sale.unavailable!
      delete admin_template_seat_sale_url(template_seat_sale), as: :json
      expect(response.body).to include 'ご指定のテンプレートは既に削除されています'
    end
  end

  # テンプレート複製
  describe 'POST /template_seat_sales/:id/duplicate' do
    subject(:duplicate_template_seat_sale) do
      post admin_duplicate_template_seat_sale_url(id: origin_template_seat_sale.id),
           params: new_attributes, as: :json
    end

    let(:new_attributes) do
      {
        title: 'new_title',
        description: 'new_description'
      }
    end
    let(:origin_template_seat_sale) { create(:template_seat_sale) }
    let(:origin_template_seat_type) { create(:template_seat_type, template_seat_sale: origin_template_seat_sale, price: 3000) }

    before do
      create(:template_seat_area, template_seat_sale: origin_template_seat_sale)
      create(:template_seat_type_option, template_seat_type: origin_template_seat_type, title: 'U-19', price: -2000)
    end

    it 'renders a successful response' do
      duplicate_template_seat_sale
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /create_template_seat_types' do
    context '正しいパラメータが渡されたされた場合(更新のみ)' do
      subject(:create_seat_sale_types) { post(admin_create_template_seat_types_path, params: params) }

      let(:params) do
        { templateSeatSale: { price: 3000,
                              option: [{ id: template_seat_type_option.id, title: '高齢者割引', price: 2000, description: '高齢者割引の説明' }] }, templateSeatSaleId: template_seat_sale.id, templateSeatTypeId: template_seat_type.id }
      end

      let(:template_seat_sale) { create(:template_seat_sale) }
      let(:template_seat_type) { create(:template_seat_type, template_seat_sale: template_seat_sale) }
      let(:template_seat_type_option) { create(:template_seat_type_option, template_seat_type: template_seat_type) }

      it '正常に値が更新される' do
        expect { create_seat_sale_types }.to change { TemplateSeatType.find(template_seat_type.id).price }
          .from(template_seat_type.price)
          .to(params[:templateSeatSale][:price]) &
                                             change { TemplateSeatTypeOption.find(template_seat_type_option.id).title }
                                             .from(template_seat_type_option.title)
                                             .to(params[:templateSeatSale][:option][0][:title])
        change { TemplateSeatTypeOption.find(template_seat_type_option.id).price }
          .from(template_seat_type_option.price)
          .to(params[:templateSeatSale][:option][0][:price])
        change { TemplateSeatTypeOption.find(template_seat_type_option.id).description }
          .from(template_seat_type_option.description)
          .to(params[:templateSeatSale][:option][0][:description])
        expect(response).to have_http_status(:ok)
      end
    end

    context '正しいパラメータが渡されたされた場合(更新とオプションの新規作成)' do
      subject(:create_seat_sale_types) { post(admin_create_template_seat_types_path, params: params) }

      let(:params) do
        { templateSeatSale: { price: 3000,
                              option: [{ id: template_seat_type_option.id, title: '高齢者割引', price: 2000, description: '' },
                                       { title: '新しい券種', price: 1000, description: '新しい券種' }] }, templateSeatSaleId: template_seat_sale.id, templateSeatTypeId: template_seat_type.id }
      end

      let(:template_seat_sale) { create(:template_seat_sale) }
      let(:template_seat_type) { create(:template_seat_type, template_seat_sale: template_seat_sale) }
      let(:template_seat_type_option) { create(:template_seat_type_option, template_seat_type: template_seat_type) }

      it '正常に値が更新および、新規作成がされる' do
        expect { create_seat_sale_types }.to change(TemplateSeatTypeOption, :count).by(1)
        change { TemplateSeatType.find(template_seat_type.id).price }
          .from(template_seat_type.price)
          .to(params[:templateSeatSale][:price]) &
          change { TemplateSeatTypeOption.find(template_seat_type_option.id).title }
          .from(template_seat_type_option.title)
          .to(params[:templateSeatSale][:option][0][:title])
        change { TemplateSeatTypeOption.find(template_seat_type_option.id).price }
          .from(template_seat_type_option.price)
          .to(params[:templateSeatSale][:option][0][:price])
        change { TemplateSeatTypeOption.find(template_seat_type_option.id).description }
          .from(template_seat_type_option.description)
          .to(params[:templateSeatSale][:option][0][:description])
        expect(response).to have_http_status(:ok)
      end
    end

    context 'template_seat_saleが削除変更不可の場合(更新とオプションの新規作成)' do
      subject(:create_seat_sale_types) { post(admin_create_template_seat_types_path, params: params) }

      let(:params) do
        { templateSeatSale: { price: 3000,
                              option: [{ id: template_seat_type_option.id, title: '高齢者割引', price: 2000, description: '' },
                                       { title: '新しい券種', price: 1000, description: '新しい券種' }] }, templateSeatSaleId: template_seat_sale.id, templateSeatTypeId: template_seat_type.id }
      end

      let(:template_seat_sale) { create(:template_seat_sale, immutable: true) }
      let(:template_seat_type) { create(:template_seat_type, template_seat_sale: template_seat_sale) }
      let(:template_seat_type_option) { create(:template_seat_type_option, template_seat_type: template_seat_type) }

      it '新規作成ができない' do
        create_seat_sale_types
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include 'ご指定のテンプレートは削除変更不可対象または販売情報、自動生成に使用されているため追加・変更できません'
      end
    end
  end

  describe 'DELETE /destroy_template_seat_type_option' do
    subject(:destroy_seat_type_option) do
      delete(admin_delete_template_seat_type_options_path(template_seat_type_option.id))
    end

    let(:template_seat_sale) { create(:template_seat_sale) }
    let(:template_seat_type) { create(:template_seat_type, template_seat_sale: template_seat_sale) }
    let!(:template_seat_type_option) { create(:template_seat_type_option, template_seat_type: template_seat_type) }

    it 'オプションのレコードを削除できる' do
      expect { destroy_seat_type_option }.to change(TemplateSeatTypeOption, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end

    context 'template_seat_saleが削除変更不可の場合' do
      let(:template_seat_sale) { create(:template_seat_sale, immutable: true) }

      it 'オプションのレコードを削除できない' do
        destroy_seat_type_option
        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include 'ご指定のテンプレートは削除変更不可対象または販売情報、自動生成に使用されているため削除できません'
      end
    end
  end
end

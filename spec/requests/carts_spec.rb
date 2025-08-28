require 'rails_helper'

RSpec.describe "/carts", type: :request do
  let(:json_response) { JSON.parse(response.body) }
  let!(:cart) { Cart.create! }
  let!(:product1) { Product.create!(name: "Test Product", price: 10.0) }
  let!(:product2) { Product.create!(name: "Second Test Product", price: 12.0) }
  let!(:cart_item) { CartItem.create!(cart: cart, product: product1, quantity: 1) }

  before do
    allow_any_instance_of(CartsController).to receive(:session).and_return({ cart_id: cart.id })
  end

  describe "POST /cart (create)" do
    context "with valid quantity" do
      it "creates a cart item and returns JSON" do
        post "/cart", params: { product_id: product1.id, quantity: 2 }, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response["id"]).to eq(cart.id)
        expect(json_response["products"].size).to eq(1)
        expect(json_response["products"].first["id"]).to eq(product1.id)
        expect(json_response["products"].first["quantity"]).to eq(3)
        expect(json_response["total_price"]).to eq(cart.total_price)
      end
    end

    context "with invalid quantity" do
      it "does not create a cart item" do
        expect {
          post "/cart", params: { product_id: product1.id, quantity: 0 }, as: :json
        }.not_to change { cart.cart_items.count }
      end

      it "returns unprocessable entity" do
        post "/cart", params: { product_id: product1.id, quantity: 0 }, as: :jso
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response["error"]).to eq("quantity must be greater than 0")
      end
    end
  end

  describe "GET /cart (show)" do
    before do
      CartItem.delete_all
      cart.add(product: product1, quantity: 1)
      cart.add(product: product2, quantity: 3)
    end

    it "returns the cart JSON with items" do
      get "/cart", as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response["id"]).to eq(cart.id)
      expect(json_response["products"].size).to eq(2)
      expect(json_response["products"].map { |i| i["id"] }).to contain_exactly(product1.id, product2.id)
      expect(json_response["total_price"]).to eq(cart.total_price)
    end
  end

  describe "POST /add_items" do
    context 'when the product already is in the cart' do
      subject do
        post '/cart/add_item', params: { product_id: product1.id, quantity: 1 }, as: :json
        post '/cart/add_item', params: { product_id: product1.id, quantity: 1 }, as: :json
      end

      it 'updates the quantity of the existing item in the cart' do
        expect { subject }.to change { cart_item.reload.quantity }.by(2)
      end

      it "adds an item to the cart and returns updated JSON" do
        subject
        expect(response).to have_http_status(:ok)
        expect(json_response["products"].last["name"]).to eq(product1.name)
        expect(json_response["products"].last["quantity"]).to eq(3)
      end
    end

    context 'when the product is not in the cart yet' do
      it 'adds a new item to the cart' do
        expect {
          post '/cart/add_item', params: { product_id: product2.id, quantity: 1 }, as: :json
        }.to change { cart.cart_items.reload.count }.by(1)
      end
    end

    context 'when the product does not exist' do
      it 'does not create a new cart item' do
        expect {
          post '/cart/add_item', params: { product_id: -1, quantity: 1 }, as: :json
        }.not_to change { cart.cart_items.count }
      end

      it 'returns a not found response' do
        post '/cart/add_item', params: { product_id: -1, quantity: 1 }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the quantity is invalid' do
      before do
        allow_any_instance_of(CartsController).to receive(:session).and_return({ cart_id: nil })
      end

      it 'does not create a new cart item' do
        expect {
          post '/cart/add_item', params: { product_id: product1.id, quantity: 0 }, as: :json
        }.not_to change { cart.cart_items.count }
      end

      it 'returns an unprocessable entity response' do
        post '/cart/add_item', params: { product_id: product1.id, quantity: 0 }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when there is no cart in the session' do
      before do
        allow_any_instance_of(CartsController).to receive(:session).and_return({ cart_id: nil })
      end

      it 'creates a new cart and adds the item' do
        expect {
          post '/cart/add_item', params: { product_id: product1.id, quantity: 1 }, as: :json

        }.to change { Cart.count }.by(1)
      end
    end
  end

  describe "DELETE /cart/:product_id (remove_item)" do
    before do
      cart.add(product: product1, quantity: 2)
    end

    context "when product exists in cart" do
      it "removes the item and returns updated JSON" do
        delete "/cart/#{product1.id}", as: :json

        expect(response).to have_http_status(:ok)
        expect(json_response["products"]).to be_empty
        expect(json_response["total_price"]).to eq(0.0)
      end
    end

    context "when product does not exist in cart" do
      it "returns 404 with error message" do
        delete "/cart/#{product2.id}", as: :json

        expect(response).to have_http_status(:not_found)
        expect(json_response["error"]).to eq("product do not exist in cart")
      end
    end
  end
end

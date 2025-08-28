class CartsController < ApplicationController
  before_action :load_or_build_cart!, only: [:create, :add_item, :show, :remove_item]

  # POST /cart
  def create
    product = Product.find(cart_params[:product_id])
    quantity = cart_params[:quantity].to_i
    return render json: { error: "quantity must be greater than 0" }, status: :unprocessable_entity if quantity <= 0

    @cart.add(product: product, quantity: quantity)
    render json: CartSerializer.new(@cart).as_json
  end

  # GET /cart
  def show
    render json: CartSerializer.new(@cart).as_json
  end

  # POST /cart/add_item
  def add_item
    product = Product.find(cart_params[:product_id])
    quantity = cart_params[:quantity].to_i
    return render json: { error: "quantity must be greater than 0" }, status: :unprocessable_entity if quantity <= 0

    @cart.add(product: product, quantity: quantity)
    render json: CartSerializer.new(@cart).as_json
  end

  # DELETE /cart/:product_id
  def remove_item
    product = Product.find(params[:product_id])
    unless @cart.cart_items.exists?(product_id: product.id)
      return render json: { error: "product do not exist in cart" }, status: :not_found
    end

    @cart.cart_items.find_by!(product_id: product.id).destroy!
    @cart.mark_as_interacted

    render json: CartSerializer.new(@cart).as_json
  end

  private

  def cart_params
    params.permit(:product_id, :quantity)
  end

  def load_or_build_cart!
    @cart = if session[:cart_id]
              Cart.find_by(id: session[:cart_id])
            else
              new_cart = Cart.create!
              session[:cart_id] = new_cart.id
              new_cart
            end
  end
end

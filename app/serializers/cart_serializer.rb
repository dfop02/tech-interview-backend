class CartSerializer
  def initialize(cart)
    @cart = cart
  end

  def as_json
    {
      id: @cart.id,
      products:
        @cart.cart_items.includes(:product).map do |item|
          unit_price = item.product.price.to_f

          {
            id: item.product.id,
            name: item.product.name,
            quantity: item.quantity,
            unit_price: unit_price,
            total_price: (item.quantity * unit_price).to_f
          }
        end,
      total_price: @cart.total_price.to_f
    }
  end
end

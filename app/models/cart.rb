class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  before_create :init_last_interaction

  def mark_as_interacted
    update!(last_interaction_at: Time.current)
  end

  def mark_as_abandoned
    update!(abandoned_at: Time.current)
  end

  def abandoned?
    abandoned_at.present?
  end

  def total_price
    cart_items.select('cart_items.quantity, products.price')
              .includes(:product)
              .sum("cart_items.quantity * products.price")
  end

  def add(product:, quantity:)
    item = cart_items.find_or_initialize_by(product_id: product.id)
    item.quantity =
      if item.new_record?
        quantity
      else
        item.quantity + quantity
      end

    raise ActiveRecord::RecordInvalid.new(item) if item.quantity <= 0

    item.save!
    mark_as_interacted
  end

  def remove_if_abandoned
    destroy! if abandoned_at && abandoned_at < 7.days.ago
  end

  private

  def init_last_interaction
    self.last_interaction_at ||= Time.current
  end
end

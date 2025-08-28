class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform(*args)
    now = Time.current

    # Marcar carrinho como abandonados
    Cart.where(abandoned_at: nil)
        .where("last_interaction_at < ?", now - 3.hours)
        .find_each { |cart| cart.mark_as_abandoned }


    # Remover carrinhos abandonados antigos
    Cart.where.not(abandoned_at: nil)
        .where("abandoned_at < ?", now - 7.days)
        .find_each(&:destroy!)
  end
end

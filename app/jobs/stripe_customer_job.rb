class StripeCustomerJob < ActiveJob::Base
  queue_as :default
 
  def perform(user)
    ActiveRecord::Base.connection_pool.with_connection do
      customer = Stripe::Customer.create(email: user.email)
      user.update_attribute :stripe_customer_id, customer.id
    end
  end
end
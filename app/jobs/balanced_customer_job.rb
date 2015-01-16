class BalancedCustomerJob < ActiveJob::Base
  queue_as :default
 
  def perform(user)
    ActiveRecord::Base.connection_pool.with_connection do
      customer = Balanced::Customer.new
      customer.save
      user.update_attribute :balanced_customer_id, customer.id
    end
  end
end
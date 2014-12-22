class User < ActiveRecord::Base
  authenticates_with_sorcery!

  has_many :properties, dependent: :destroy
  has_many :payments, autosave: true, dependent: :destroy

  after_create :create_stripe_customer

  def name
    first_name + ' ' + last_name
  end

  private

  def create_stripe_customer
    StripeCustomerJob.perform_later self
  end
end

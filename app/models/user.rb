class User < ActiveRecord::Base
  authenticates_with_sorcery!

  has_many :properties, dependent: :destroy
  has_many :payments, autosave: true, dependent: :destroy

  validates_presence_of :email, :first_name

  after_create :create_stripe_customer

  def name
    first_name + ' ' + last_name
  end

  def avatar
    if false #photo
      photo.url
    else
      "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}.jpg?s=60&d=identicon"
    end
  end

  private

  def create_stripe_customer
    StripeCustomerJob.perform_later self
  end
end

class User < ActiveRecord::Base
  authenticates_with_sorcery!

  has_many :properties, dependent: :destroy
  has_many :payments, autosave: true, dependent: :destroy

  validates_presence_of :email, :password, :password_confirmation, if: lambda { validate_step_1 }
  validates :password, confirmation: true, if: lambda { self.validate_step_1 }

  validates_presence_of :first_name, :last_name, :phone_number, if: lambda { validate_step_2 }
  validates_numericality_of :phone_number, only_integer: true, if: lambda { validate_step_2 }
  validates_length_of :phone_number, is: 10, if: lambda { validate_step_2 }

  after_create :create_stripe_customer

  cattr_accessor :validate_step_1, :validate_step_2

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

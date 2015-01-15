class User < ActiveRecord::Base
  authenticates_with_sorcery!

  before_validation :format_phone_number

  has_many :properties, dependent: :destroy
  has_many :payments, autosave: true, dependent: :destroy

  validates_uniqueness_of :email, if: lambda { step == 'step1' || step == 'edit_info' }
  validates_presence_of :email, if: lambda { step == 'step1' || step == 'edit_info' }
  validates_presence_of :password, :password_confirmation, if: lambda { step == 'step1' || step == 'edit_password' }
  validates :password, confirmation: true, if: lambda { step == 'step1' || step == 'edit_password' }

  validates_presence_of :first_name, :last_name, :phone_number, if: lambda { step == 'step2' || step == 'edit_info' }
  validates_numericality_of :phone_number, only_integer: true, if: lambda { step == 'step2' || step == 'edit_info' }
  validates_length_of :phone_number, is: 10, if: lambda { step == 'step2' || step == 'edit_info' }

  after_create :create_stripe_customer

  cattr_accessor :step

  def name
    first_name + ' ' + last_name
  end

  def avatar
    if false #photo
      photo.url
    else
      "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}.jpg?s=60&d=mm"
    end
  end

  private

  def create_stripe_customer
    StripeCustomerJob.perform_later self
  end

  def format_phone_number
    self.phone_number = phone_number.strip.gsub(' ', '').delete("()-") if phone_number.present?
  end
end

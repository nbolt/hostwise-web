class User < ActiveRecord::Base
  authenticates_with_sorcery!

  include PgSearch

  before_validation :format_phone_number

  has_many :properties, dependent: :destroy
  has_many :payments, autosave: true, dependent: :destroy
  has_many :avatars, autosave: true, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :contractor_jobs, class_name: 'ContractorJobs'
  has_many :jobs, through: :contractor_jobs
  has_one  :contractor_profile, dependent: :destroy

  as_enum :role, admin: 0, host: 1, contractor: 2

  pg_search_scope :search_contractors, against: [:email, :first_name, :last_name, :phone_number], associated_against: {contractor_profile: [:address1, :city, :zip]}, using: { tsearch: { prefix: true } }

  validates_uniqueness_of :email, if: lambda { step == 'step1' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile'}
  validates_presence_of :email, if: lambda { step == 'step1' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile' }

  validates_presence_of :password, :password_confirmation, if: lambda { step == 'step1' || step == 'edit_password' || step == 'contractor_profile' }
  validates :password, confirmation: true, if: lambda { step == 'step1' || step == 'edit_password' || step == 'contractor_profile' }

  validates_presence_of :first_name, :last_name, :phone_number, if: lambda { step == 'step2' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile' }
  validates_numericality_of :phone_number, only_integer: true, if: lambda { step == 'step2' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile' }
  validates_length_of :phone_number, is: 10, if: lambda { step == 'step2' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile' }

  validates_numericality_of :secondary_phone, only_integer: true, if: lambda { self.secondary_phone.present? && step == 'contractor_profile' }
  validates_length_of :secondary_phone, is: 10, if: lambda { self.secondary_phone.present? && step == 'contractor_profile' }

  after_create :create_stripe_customer, :create_balanced_customer

  attr_accessor :step

  def name
    first_name + ' ' + last_name
  end

  def avatar
    if avatars.empty?
      "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}.jpg?s=60&d=mm"
    else
      avatars.last.photo.url
    end
  end

  def claim_job job
    if job.contractors.count == job.size
      false
    else
      job.contractors.push self
      if job.contractors.count == job.size
        job.scheduled!
        job.save
      end
      fanout = Fanout.new ENV['FANOUT_ID'], ENV['FANOUT_KEY']
      fanout.publish_async 'jobs', {}
      true
    end
  end

  def drop_job job
    job.contractors.delete self
    job.open!
    job.save
    fanout = Fanout.new ENV['FANOUT_ID'], ENV['FANOUT_KEY']
    fanout.publish_async 'jobs', {}
    true
  end

  def self.contractors(term = nil)
    results = User.where(role_cd: 2)
    return results.search_contractors(term) if term.present?
    results
  end

  private

  def create_stripe_customer
    StripeCustomerJob.perform_later self
  end

  def create_balanced_customer
    BalancedCustomerJob.perform_later self
  end

  def format_phone_number
    self.phone_number = phone_number.strip.gsub(' ', '').delete("()-.+") if phone_number.present?
  end
end

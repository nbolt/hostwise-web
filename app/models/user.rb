class User < ActiveRecord::Base
  authenticates_with_sorcery!
  include SorceryHelper

  include PgSearch

  before_validation :format_phone_number

  has_many :properties, dependent: :destroy
  has_many :payments, autosave: true, dependent: :destroy
  has_many :avatars, autosave: true, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :contractor_jobs, class_name: 'ContractorJobs'
  has_many :jobs, through: :contractor_jobs
  has_one  :contractor_profile, dependent: :destroy
  has_one  :availability, dependent: :destroy
  has_one  :background_check, dependent: :destroy
  has_many :service_notifications, dependent: :destroy

  as_enum :role, admin: 0, host: 1, contractor: 2

  has_settings :new_open_job, :job_claim_confirmation, :service_reminder, :booking_confirmation, :service_completion

  pg_search_scope :search_contractors, against: [:email, :first_name, :last_name, :phone_number], associated_against: {contractor_profile: [:address1, :city, :zip]}, using: { tsearch: { prefix: true } }
  pg_search_scope :search_hosts, against: [:email, :first_name, :last_name, :phone_number], using: { tsearch: { prefix: true } }

  validates_uniqueness_of :email, if: lambda { step == 'step1' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile'}
  validates_presence_of :email, if: lambda { step == 'step1' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile' }

  validates_presence_of :password, :password_confirmation, if: lambda { step == 'step1' || step == 'edit_password' || step == 'contractor_profile' }
  validates :password, confirmation: true, if: lambda { step == 'step1' || step == 'edit_password' || step == 'contractor_profile' }

  validates_presence_of :first_name, :last_name, :phone_number, if: lambda { step == 'step2' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile' }
  validates_numericality_of :phone_number, only_integer: true, if: lambda { step == 'step2' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile' }
  validates_length_of :phone_number, is: 10, if: lambda { step == 'step2' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile' }

  validates_numericality_of :secondary_phone, only_integer: true, if: lambda { self.secondary_phone.present? }
  validates_length_of :secondary_phone, is: 10, if: lambda { self.secondary_phone.present? }

  after_create :create_stripe_customer, :create_balanced_customer

  attr_accessor :step

  def name
    first_name + ' ' + last_name if first_name.present? && last_name.present?
  end

  def display_phone_number
    first  = phone_number[0..2]
    second = phone_number[3..5]
    third  = phone_number[6..9]
    "(#{first}) #{second}-#{third}"
  end

  def avatar
    if avatars.empty?
      "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}.jpg?d=https%3A%2F%2Fs3.amazonaws.com%2Fhostwise-production%2Fgeneric_user.png"
    else
      avatars.last.photo.url
    end
  end

  def notification_settings
    to_settings_hash
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
      job.handle_distribution_job self
      Job.set_priorities self.jobs.on_date(job.booking.date).standard
      fanout = Fanout.new ENV['FANOUT_ID'], ENV['FANOUT_KEY']
      fanout.publish_async 'jobs', {}
      true
    end
  end

  def drop_job job
    job.contractors.delete self
    job.open!
    job.save
    job.handle_distribution_job self
    Job.set_priorities self.jobs.on_date(job.booking.date).standard
    if job.contractors[0]
      job.handle_distribution_job job.contractors[0].jobs.on_date(job.booking.date).standard
      Job.set_priorities job.contractors[0].jobs.on_date(job.booking.date).standard
    end
    fanout = Fanout.new ENV['FANOUT_ID'], ENV['FANOUT_KEY']
    fanout.publish_async 'jobs', {}
    true
  end

  def self.contractors(term = nil)
    results = User.where(role_cd: 2)
    return results.search_contractors(term) if term.present?
    results
  end

  def self.hosts(term = nil)
    results = User.where(role_cd: 1)
    return results.search_hosts(term) if term.present?
    results
  end

  def next_job_date
    jobs = self.jobs.upcoming self
    return jobs.sort_by{|j| j.booking.date}.first.booking.date if jobs.present?
  end

  def next_service_date
    bookings = Booking.upcoming(self)
    return bookings.first.date unless bookings.empty?
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

class User < ActiveRecord::Base
  authenticates_with_sorcery!
  include SorceryHelper

  include PgSearch

  before_validation :format_phone_number
  after_save :handle_deactivation

  has_many :properties, dependent: :destroy
  has_many :payments, autosave: true, dependent: :destroy
  has_many :avatars, autosave: true, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :contractor_jobs, class_name: 'ContractorJobs', dependent: :destroy
  has_many :jobs, through: :contractor_jobs
  has_one  :contractor_profile, dependent: :destroy
  has_one  :availability, dependent: :destroy
  has_one  :background_check, dependent: :destroy
  has_many :service_notifications, dependent: :destroy
  has_many :payouts

  as_enum :role, admin: 0, host: 1, contractor: 2

  has_settings :new_open_job, :job_claim_confirmation, :service_reminder, :booking_confirmation, :service_completion, :porter_arrived, :property_added, :porter_en_route

  pg_search_scope :search_contractors, against: [:email, :first_name, :last_name, :phone_number], associated_against: {contractor_profile: [:address1, :city, :zip]}, using: { tsearch: { prefix: true } }
  pg_search_scope :search_hosts, against: [:email, :first_name, :last_name, :phone_number], using: { tsearch: { prefix: true } }

  scope :trainers, -> { where('position_cd = 3').includes(:contractor_profile).references(:contractor_profile) }
  scope :trainees, -> { where('position_cd = 1').includes(:contractor_profile).references(:contractor_profile) }
  scope :team_members, -> { where('position_cd in (2,3) ').includes(:contractor_profile).references(:contractor_profile) }
  scope :contractors, -> { where(role_cd: 2) }
  scope :available_contractors, -> (booking) {
    day =
      case booking.date.wday
      when 0 then 'sun'
      when 1 then 'mon'
      when 2 then 'tues'
      when 3 then 'wed'
      when 4 then 'thurs'
      when 5 then 'fri'
      when 6 then 'sat'
      end

    where(activation_state: 'active').where("availabilities.#{day} = ?", true).where(contractor_profiles: {position_cd: [2,3]}).includes(:availability, :contractor_profile).references(:availability, :contractor_profile)
  }

  validates_uniqueness_of :email, if: lambda { step == 'step1' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile'}
  validates_presence_of :email, if: lambda { step == 'step1' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile' }

  validates_presence_of :password, :password_confirmation, if: lambda { step == 'step1' || step == 'edit_password' || step == 'contractor_profile' }
  validates :password, confirmation: true, if: lambda { step == 'step1' || step == 'edit_password' || step == 'contractor_profile' }

  validates_presence_of :first_name, :last_name, :phone_number, if: lambda { step == 'step2' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile' }
  validates_numericality_of :phone_number, only_integer: true, if: lambda { step == 'step2' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile' }
  validates_length_of :phone_number, is: 10, if: lambda { step == 'step2' || step == 'edit_info' || step == 'contractor_info' || step == 'contractor_profile' }

  validates_numericality_of :secondary_phone, only_integer: true, if: lambda { self.secondary_phone.present? }
  validates_length_of :secondary_phone, is: 10, if: lambda { self.secondary_phone.present? }

  attr_accessor :step

  def name
    if first_name.present? && last_name.present?
      return "#{first_name} #{last_name[0]}."
    elsif first_name.present?
      return first_name
    else
      return ''
    end
  end

  def display_phone_number
    if phone_number
      first  = phone_number[0..2]
      second = phone_number[3..5]
      third  = phone_number[6..9]
      "(#{first}) #{second}-#{third}"
    else
      ''
    end
  end

  def avatar
    if avatars.empty?
      "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}.jpg?d=https%3A%2F%2Fs3.amazonaws.com%2Fhostwise-production%2Fgeneric_user.png"
    else
      avatars.last.photo.url
    end
  end

  def bookings
    properties.map(&:bookings).flatten
  end

  def booking_count
    bookings.count
  end

  def notification_settings
    to_settings_hash
  end

  def earnings
    payouts.where(status_cd: 1).reduce(0){|acc, payout| acc + payout.amount} / 100.0
  end

  def unpaid
    payouts.where(status_cd: 0).reduce(0){|acc, payout| acc + payout.amount} / 100.0
  end

  def man_hours date
    jobs.standard.on_date(date).reduce(0){|acc, job| acc + job.man_hours} if role_cd == 2
  end

  def last_payout_date
    payouts.where(status_cd: 2).order('updated_at DESC').first.then(:updated_at)
  end

  def completed_jobs
    jobs.complete
  end

  def cancelled_jobs
    jobs.cancelled
  end

  def claim_job job, admin=false
    jobs_today = self.jobs.on_date(job.date)
    team_members = job.contractors.team_members
    if team_members.count == job.size && !admin
      { success: false, message: "Job already has assigned number of contractors" }
    elsif team_members.count == job.size && admin && team_members.find {|c| (c.jobs.on_date(job.date) - [job]).find {|j| j.contractors.count > 1}}
      { success: false, message: "Can't create team job as other team members already have team jobs for this day" }
    elsif man_hours(job.date) + job.man_hours > MAX_MAN_HOURS && !admin
      { success: false, message: "Job would surpass maximum number of contractor man hours for the day" }
    elsif job.training
      { success: false, message: "Can't claim jobs with applicants attached" }
    elsif job.size > 1 && jobs_today.find {|job| job.contractors.count > 1}
      { success: false, message: "Can't claim more team jobs for the day" }
    elsif job.cancelled?
      { success: false, message: "Can't claim a cancelled job" }
    elsif payments.empty?
      { success: false, message: "Cannot claim jobs until you setup a payout method" }
    elsif job.contractors.index self
      { success: true }
    else
      job.contractors.push self
      team_members = job.contractors.team_members
      job.contractor_jobs[0].update_attribute :primary, true if job.contractors.count == 1
      job.size = team_members.count if team_members.count > job.size
      if team_members.count == job.size
        job.scheduled!
        job.save
      end
      job.handle_distribution_jobs self
      job.contractors.each {|contractor| Job.set_priorities contractor.jobs.on_date(job.date), contractor}
      unless Rails.env.test?
        fanout = Fanout.new ENV['FANOUT_ID'], ENV['FANOUT_KEY']
        fanout.publish_async 'jobs', {}
      end
      { success: true }
    end
  end

  def drop_job job, admin=false
    primary = ContractorJobs.where(job_id: job.id, user_id: self.id)[0].primary
    job.contractors.destroy self
    job.size = job.contractors.count if job.booking && job.contractors.count >= job.minimum_job_size
    if self.contractor_profile.position == :trainee
      job.training = false
    else
      job.training = false if self.contractor_profile.position == :trainer
      job.open!
    end
    job.save
    job.handle_distribution_jobs self
    Job.set_priorities self.jobs.on_date(job.date), self

    if admin
      TwilioJob.perform_later("+1#{self.phone_number}", "Oops! Looks like job ##{job.id} on #{job.formatted_date} was cancelled. Sorry about this!")
    end

    if job.contractors[0]
      trainee = job.contractors.trainees[0]
      team_members = job.contractors.team_members
      mentors = job.contractors.trainers
      if trainee
        if mentors.present?
          prev_payout = job.payout mentors[0]
          job.update_attribute :training, true
          TwilioJob.perform_later("+1#{mentors[0].phone_number}", "Your job on #{job.formatted_date} is now a mentor job. Payout has increased from $#{prev_payout} to $#{job.payout(mentors[0])}!")
        else
          job.contractors.destroy trainee
          TwilioJob.perform_later("+1#{trainee.phone_number}", "Oops! Your Test & Tips session on #{job.formatted_date} was cancelled. Please select another session!")
        end
      end
      if team_members[0]
        ContractorJobs.where(job_id: job.id, user_id: mentors[0].then(:id) || team_members[0].id)[0].update_attribute :primary, true if primary
        team_members.each do |contractor|
          job.handle_distribution_jobs contractor
          jobs = contractor.jobs.on_date(job.date)
          Job.set_priorities jobs, contractor
        end
      end
    end
    unless Rails.env.test?
      fanout = Fanout.new ENV['FANOUT_ID'], ENV['FANOUT_KEY']
      fanout.publish_async 'jobs', {}
    end
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
    return jobs.sort_by{|j| j.date}[0].chain(:booking, :date) if jobs.present?
  end

  def next_service_date
    bookings = Booking.upcoming(self)
    return bookings.first.date unless bookings.empty?
  end

  def show_quiz
    completed_jobs = Job.standard.past(self).count
    passed_quizzes = QuizStage.passed(self.contractor_profile)
    last_quiz = passed_quizzes.count > 0 ? passed_quizzes[0] : nil
    take_at = last_quiz.present? ? last_quiz.next : 0
    return completed_jobs == take_at
  end

  def create_stripe_customer
    customer = Stripe::Customer.create(email: email)
    self.update_attribute :stripe_customer_id, customer.id
  end

  def deactivated?
    self.activation_state == 'deactivated'
  end

  private

  def format_phone_number
    self.phone_number = phone_number.strip.gsub(' ', '').delete("()-.+") if phone_number.present?
  end

  def handle_deactivation
    if activation_state_changed? && activation_state == 'deactivated'
      self.jobs.where(status_cd: [0,1]).each do |job|
        self.drop_job job, true
      end

      self.properties.each do |property|
        property.bookings.active.each do |booking|
          if booking.job
            booking.job.contractors.each do |contractor|
              contractor.drop_job booking.job, true
            end
          end

          booking.deleted!
          booking.save
        end
      end
    end
  end
end

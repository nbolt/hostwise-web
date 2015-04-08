class Booking < ActiveRecord::Base
  include PgSearch
  pg_search_scope :search, against: [:id], associated_against: {user: [:first_name, :last_name, :email], property: [:title, :address1, :city, :state, :zip, :user_id]}, using: { tsearch: { prefix: true } }

  belongs_to :property
  belongs_to :payment

  has_one :job, autosave: true, dependent: :destroy
  has_one :user, through: :booking_users
  has_one :booking_users, dependent: :destroy
  has_many :booking_services, class_name: 'BookingServices', dependent: :destroy
  has_many :services, through: :booking_services
  has_many :transactions

  scope :pending, -> { where('services.id is null or bookings.payment_id is null').includes(:services).references(:services) }
  scope :on_date, -> (date) { where('extract(year from date) = ? and extract(month from date) = ? and extract(day from date) = ?', date.year, date.month, date.day) }
  scope :today, -> { where('date = ?', Date.today) }
  scope :tomorrow, -> { where('date = ?', Date.today + 1) }
  scope :upcoming, -> (user) { where(status_cd: [1,4]).where('bookings.property_id = properties.id and properties.user_id = ? and bookings.date > ?', user.id, Date.today).order(date: :asc).includes(:property).references(:property) }
  scope :future, -> { where('date >= ?', Date.today) }
  scope :past, -> { where('date < ?', Date.today) }
  scope :by_user, -> (user) { where('user_id = ?', user.id).includes(property: [:user]).references(:user) }
  scope :active, -> { where(status_cd: 1) }

  before_save :check_transaction
  before_create :create_job
  after_create :attach_user

  as_enum :status, deleted: 0, active: 1, cancelled: 2, completed: 3, manual: 4, couldnt_access: 5
  as_enum :payment_status, pending: 0, completed: 1

  attr_accessor :vip

  def self.cost property, services, first_booking_discount = false, late_next_day = false, late_same_day = false, no_access_fee = false
    pool_service = Service.where(name: 'pool')[0]
    total = 0
    rsp = {}
    services.each do |service|
      case service.name
        when 'cleaning'
          rsp[:cleaning] = PRICING[property.property_type.to_s][property.bedrooms][property.bathrooms]
        when 'linens'
          rsp[:linens] ||= 0
          property.king_beds.times  { rsp[:linens] += PRICING['king_linens']  }
          property.queen_beds.times { rsp[:linens] += PRICING['queen_linens'] }
          property.full_beds.times  { rsp[:linens] += PRICING['full_linens']  }
          property.twin_beds.times  { rsp[:linens] += PRICING['twin_linens']  }
        when 'toiletries'
          rsp[:toiletries] ||= 0
          property.bathrooms.times  { rsp[:toiletries] += PRICING['toiletries']  }
        when 'pool'
          rsp[:pool] = PRICING['pool']
        when 'patio'
          rsp[:patio] = PRICING['patio']
        when 'windows'
          rsp[:windows] = PRICING['windows']
        when 'preset'
          rsp[:preset] = PRICING['preset'][property.beds]
      end
    end
    rsp[:cost] = rsp.reduce(0){|total, service| total + service[1]}
    if late_next_day
      rsp[:late_next_day] = PRICING['late_next_day']
      rsp[:cost] += PRICING['late_next_day']
    end
    if late_same_day
      rsp[:late_same_day] = PRICING['late_same_day']
      rsp[:cost] += PRICING['late_same_day']
    end
    rsp[:cost] += PRICING['no_access_fee'] if no_access_fee
    if first_booking_discount
      discount = PRICING['first_booking_discount']
      if discount <= rsp[:cost]
        rsp[:first_booking_discount] = discount
      else
        rsp[:first_booking_discount] = rsp[:cost]
      end
      rsp[:cost] -= rsp[:first_booking_discount]
    end
    rsp
  end

  def cost
    cost = Booking.cost(property, services, first_booking_discount, late_next_day, late_same_day, no_access_fee)
    if cancelled? || couldnt_access?
      cost[:cost] -= cost[:linens] if cost[:linens]          # |
      cost[:cost] -= cost[:toiletries] if cost[:toiletries]  # |  NOTE: tests needed [mutation coverage]
      cost[:cost] = 0 if cost[:cost] < 0                     # |
      [PRICING['cancellation'], (cost[:cost] * 0.2).round(2)].max
    else
      cost[:cost]
    end
  end

  def send_reminder
    # notify host
    UserMailer.booking_reminder(self, self.property.user).then(:deliver) if self.property.user.settings(:service_reminder).email

    # notify contractor
    if self.job
      self.job.contractors.each do |contractor|
        UserMailer.booking_reminder(self, contractor).then(:deliver) if contractor.settings(:service_reminder).email
        if contractor.settings(:service_reminder).sms && !contractor.deactivated?
          pickup_job = contractor.jobs.on_date(self.date).pickup[0]
          sms = "Tomorrow you have a HostWise job at #{self.property.short_address}."
          sms += " Don't forget to pick up supplies at 9:30 at #{pickup_job.distribution_center.short_address}." if pickup_job
          TwilioJob.perform_later("+1#{contractor.phone_number}", sms)
        end
      end
    end
  end

  def charge!
    if self.payment_status == :completed
      false
    elsif cost == 0
      save
    elsif payment.stripe_id
      amount = (cost * 100).to_i
      begin
        metadata = { job_id: job.id, booking_id: self.id, user_id: user.id, user_email: user.email }
        if cancelled?
          metadata[:cancellation] = true
        elsif couldnt_access?
          metadata[:couldnt_access] = true
        end
        rsp = Stripe::Charge.create(
          amount: amount,
          currency: 'usd',
          customer: property.user.stripe_customer_id,
          source: payment.stripe_id,
          statement_descriptor: "HostWise #{id}"[0..21], # 22 characters max
          metadata: metadata
        )
        transactions.create(stripe_charge_id: rsp.id, status_cd: 0, amount: amount)
        save
      rescue Stripe::CardError => e
        err  = e.json_body[:error]
        transactions.create(stripe_charge_id: err[:charge], status_cd: 1, failure_message: err[:message], amount: amount)
        UserMailer.generic_notification("Stripe Payment Failed - ***#{payment.last4}: #{property.user.name}", "Booking ID: #{id}").then(:deliver)
        false
      end
    else
      false
    end
  end

  def last_transaction
    transactions.order(created_at: :asc).last
  end

  def same_day_cancellation
    timezone = Timezone::Zone.new :zone => property.zone
    day = (self.date.to_date - timezone.time(Time.now).to_date).to_i
    return true if day == 0 || (day == 1 && timezone.time(Time.now).hour >= 22) # subject to cancellation if same day or the day before after 10pm
    return false
  end

  def formatted_date
    date.strftime '%m/%d/%Y'
  end

  def duplicate?
    existing_booking = property.bookings.active.on_date(date)[0]
    if existing_booking
      if existing_booking == self
        false
      else
        true
      end
    else
      false
    end
  end

  private

  def create_job
    if status_cd != 4
      job = self.build_job(status_cd: 0, date: date)
      job.state_cd = 1 if vip
      job.size = 2 if (property.bedrooms == 3 && property.bathrooms >= 3) || property.bedrooms > 3
    end
  end

  def check_transaction
    if self.payment_status != :completed && last_transaction && last_transaction.successful? || cost == 0
      self.payment_status = :completed
    end
  end

  def attach_user
    self.user = property.user
  end

end

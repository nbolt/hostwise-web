class Booking < ActiveRecord::Base
  include PgSearch
  pg_search_scope :search, associated_against: {property: [:title, :address1, :city, :state, :zip, :user_id]}, using: { tsearch: { prefix: true } }

  belongs_to :property
  belongs_to :payment

  has_one :job, autosave: true, dependent: :destroy
  has_many :booking_services, class_name: 'BookingServices', dependent: :destroy
  has_many :services, through: :booking_services
  has_many :transactions

  scope :pending, -> { where('services.id is null or bookings.payment_id is null').includes(:services).references(:services) }
  scope :active,  -> { where('services.id is not null and bookings.payment_id is not null').includes(:services).references(:services) }
  scope :tomorrow, -> { where('date = ?', Date.today + 1) }
  scope :upcoming, -> (user) { where(status_cd: [1,4]).where('bookings.property_id = properties.id and properties.user_id = ? and bookings.date > ?', user.id, Date.today).order(date: :asc).includes(:property).references(:property) }
  scope :future, -> { where('date >= ?', Date.today) }
  scope :by_user, -> (user) { where('user_id = ?', user.id).includes(property: [:user]).references(:user) }
  scope :active, -> { where(status_cd: 1) }

  before_create :create_job
  before_save :create_order, :check_transaction

  as_enum :status, deleted: 0, active: 1, cancelled: 2, completed: 3, manual: 4
  as_enum :payment_status, pending: 0, completed: 1

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
          rsp[:patio] = PRICING['patio'] unless services.index pool_service
        when 'windows'
          rsp[:windows] = PRICING['windows'] unless services.index pool_service
        when 'preset'
          rsp[:preset] = PRICING['preset']
      end
    end
    rsp[:cost] = rsp.reduce(0){|total, service| total + service[1]}
    rsp[:cost] += PRICING['late_next_day'] if late_next_day
    rsp[:cost] += PRICING['late_same_day'] if late_same_day
    rsp[:cost] += PRICING['no_access_fee'] if no_access_fee
    if first_booking_discount
      rsp[:first_booking_discount] = PRICING['first_booking_discount']
      rsp[:cost] -= rsp[:first_booking_discount]
      rsp[:cost] = 0 if rsp[:cost] < 0
    end
    rsp
  end

  def cost
    return PRICING['cancellation'] if cancelled?
    Booking.cost(property, services, first_booking_discount, late_next_day, late_same_day, no_access_fee)[:cost]
  end

  def send_reminder
    UserMailer.booking_reminder(self).then(:deliver)
  end

  def charge!
    if completed?
      false
    elsif cost == 0
      true
    elsif payment.stripe_id
      amount = cost * 100
      begin
        metadata = {}
        if cancelled?
          metadata[:cancellation] = true
        else
          metadata[:job_id] = job.id
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
        false
      end
    elsif payment.balanced_id
      verification = Balanced::BankAccountVerification.fetch("/verifications/#{payment.balanced_verification_id}")
      if verification.verification_status == 'succeeded'
        bank_account = Balanced::BankAccount.fetch("/bank_accounts/#{payment.balanced_id}")
        order = Balanced::Order.fetch("/orders/#{balanced_order_id}")
        amount = cost * 100
        rsp = order.debit_from(
          source: bank_account,
          amount: amount
        )
        transactions.create(balanced_charge_id: rsp.id, status_cd: 2, amount: amount)
        save
      else
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
    day = (self.date.to_date - Date.today).to_i
    return true if day == 0 || (day <= 1 && Time.now.hour >= 12)
    return false
  end

  private

  def create_job
    if status_cd != 4
      job = self.build_job(status_cd: 0, date: date)
      job.size = 2 if property.bedrooms > 4
    end
  end

  def create_order
    if payment && payment.balanced_id && !balanced_order_id
      customer = Balanced::Customer.fetch("/customers/#{property.user.balanced_customer_id}")
      order = customer.create_order(meta: {booking_id: id})
      self.balanced_order_id = order.id
    end
  end

  def check_transaction
    if !completed? && last_transaction && last_transaction.successful? || cost == 0
      completed!
    end
  end

end

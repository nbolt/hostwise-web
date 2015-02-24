class Booking < ActiveRecord::Base
  belongs_to :property
  belongs_to :payment

  has_one :job, autosave: true, dependent: :destroy
  has_many :booking_services, class_name: 'BookingServices', dependent: :destroy
  has_many :services, through: :booking_services
  has_many :transactions

  scope :pending, -> { where('services.id is null or bookings.payment_id is null').includes(:services).references(:services) }
  scope :active,  -> { where('services.id is not null and bookings.payment_id is not null').includes(:services).references(:services) }
  scope :tomorrow, -> { where('date = ?', Date.today + 1) }
  scope :upcoming, -> (user) { where('bookings.property_id = properties.id and properties.user_id = ? and bookings.date > ?', user.id, Date.today).order(date: :asc).includes(:property).references(:property) }
  scope :future, -> { where('date >= ?', Date.today) }

  before_create :create_job
  before_save :create_order
  after_save :check_transaction

  as_enum :payment_status, pending: 0, completed: 1

  def self.cost property, services
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
        property.beds.times  { rsp[:toiletries] += PRICING['toiletries']  }
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
    rsp
  end

  def cost
    Booking.cost(property, services)[:cost]
  end

  def send_reminder
    UserMailer.booking_reminder(self).then(:deliver)
  end

  def charge!
    if completed?
      false
    elsif payment.stripe_id
      begin
        rsp = Stripe::Charge.create(
          amount: cost * 100,
          currency: 'usd',
          customer: property.user.stripe_customer_id,
          card: payment.stripe_id,
          statement_descriptor: "HostWise #{id}"[0..21], # 22 characters max
          metadata: { job_id: job.id }
        )
        transactions.create(stripe_charge_id: rsp.id, status_cd: 0, amount: cost * 100)
        save
      rescue Stripe::CardError => e
        err  = e.json_body[:error]
        transactions.create(stripe_charge_id: err[:charge], status_cd: 1, failure_message: err[:message], amount: cost * 100)
        false
      end
    elsif payment.balanced_id
      verification = Balanced::BankAccountVerification.fetch("/verifications/#{payment.balanced_verification_id}")
      if verification.verification_status == 'succeeded'
        bank_account = Balanced::BankAccount.fetch("/bank_accounts/#{payment.balanced_id}")
        order = Balanced::Order.fetch("/orders/#{balanced_order_id}")
        rsp = order.debit_from(
          source: bank_account,
          amount: cost * 100
        )
        transactions.create(balanced_charge_id: rsp.id, status_cd: 2, amount: booking.cost * 100)
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

  private

  def create_job
    job = self.build_job(status_cd: 0)
    job.size = 2 if property.bedrooms > 4
  end

  def create_order
    if payment && payment.balanced_id && !balanced_order_id
      customer = Balanced::Customer.fetch("/customers/#{property.user.balanced_customer_id}")
      order = customer.create_order(meta: {booking_id: id})
      self.balanced_order_id = order.id
    end
  end

  def check_transaction
    if !completed? && last_transaction && last_transaction.successful?
      completed!
    end
  end

end

class Booking < ActiveRecord::Base
  belongs_to :property
  belongs_to :payment

  has_one :job, autosave: true, dependent: :destroy
  has_many :booking_services, class_name: 'BookingServices', dependent: :destroy
  has_many :services, through: :booking_services
  has_many :transactions

  scope :pending, -> { includes(:services).where('services.id is null or bookings.payment_id is null').references(:services) }
  scope :active,  -> { includes(:services).where('services.id is not null and bookings.payment_id is not null').references(:services) }
  scope :tomorrow, -> { where('date = ?', Date.today + 1) }
  scope :upcoming, -> (user) { includes(:property).references(:property).where('bookings.property_id = properties.id and properties.user_id = ? and bookings.date > ?', user.id, Date.today).order(date: :asc) }
  scope :future, -> { where('date >= ?', Date.today) }

  before_save :create_job, on: :create
  before_save :create_order
  after_save :check_transaction

  as_enum :payment_status, pending: 0, completed: 1

  def cost
    total = 0
    services.each do |service|
      total += 19
    end
    total
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

  private

  def create_job
    self.build_job(status_cd: 0)
  end

  def create_order
    if payment.balanced_id && !balanced_order_id
      customer = Balanced::Customer.fetch("/customers/#{booking.property.user.balanced_customer_id}")
      order = customer.create_order(meta: {booking_id: id})
      self.balanced_order_id = order.id
    end
  end

  def check_transaction
    if transactions.last && transactions.last.successful?
      completed!
    end
  end

end

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

  private

  def create_job
    self.build_job(status_cd: 0)
  end

  def create_order
    if payment.balanced_id && !balanced_order_id
      customer = Balanced::Customer.fetch("/customers/#{booking.property.user.balanced_customer_id}")
      order = customer.create_order(meta: {job_id: id})
      self.balanced_order_id = order.id
    end
  end

end

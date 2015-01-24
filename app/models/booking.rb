class Booking < ActiveRecord::Base
  belongs_to :property
  belongs_to :payment

  has_many :booking_services, class_name: 'BookingServices', dependent: :destroy
  has_many :services, through: :booking_services

  has_many :contractor_jobs, class_name: 'ContractorJobs'
  has_many :contractors, through: :contractor_jobs, source: :user

  as_enum :status, open: 0, scheduled: 1, complete: 2

  scope :pending, -> { includes(:services).where('services.id is null or bookings.payment_id is null').references(:services) }
  scope :active,  -> { includes(:services).where('services.id is not null and bookings.payment_id is not null').references(:services) }
  scope :tomorrow, -> { where('date = ?', Date.today + 1) }

  def self.open contractor
    Booking.includes(:contractor_jobs).references(:contractor_jobs).where(status_cd: 0).where('contractor_jobs.user_id is null or contractor_jobs.user_id != ?', contractor.id)
  end

  def self.upcoming contractor
    Booking.includes(:contractor_jobs).references(:contractor_jobs).where(status_cd: [0, 1]).where('contractor_jobs.user_id = ?', contractor.id)
  end

  def self.past contractor
    Booking.includes(:contractor_jobs).references(:contractor_jobs).where(status_cd: 2).where('contractor_jobs.user_id = ?', contractor.id)
  end

  def cost
    total = 0
    services.each do |service|
      total += 19
    end
    total
  end

  def size
    services.count
  end

  def send_reminder
    UserMailer.booking_reminder(self).then(:deliver)
  end

end

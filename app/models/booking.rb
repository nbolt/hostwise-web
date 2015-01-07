class Booking < ActiveRecord::Base
  belongs_to :property
  belongs_to :payment

  has_many :booking_services, class_name: 'BookingServices', dependent: :destroy
  has_many :services, through: :booking_services

  scope :pending, -> { includes(:services).where('services.id is null or bookings.payment_id is null').references(:services) }
  scope :active,  -> { includes(:services).where('services.id is not null and bookings.payment_id is not null').references(:services) }
  scope :tomorrow, -> { where('date::date - now()::date = 1') }

  def send_reminder
    UserMailer.booking_reminder(self).deliver
  end
end

class Service < ActiveRecord::Base
  has_many :booking_services, class_name: 'BookingServices', dependent: :destroy
  has_many :bookings, through: :booking_services
end

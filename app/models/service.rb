class Service < ActiveRecord::Base
  has_many :booking_services, class_name: 'BookingServices', dependent: :destroy
  has_many :bookings, through: :booking_services

  scope :extra, -> { where(extra: true, hidden: false) }
  scope :standard, -> { where(extra: false, hidden: false) }

  def serializer_display
    display
  end
end

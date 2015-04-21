class Coupon < ActiveRecord::Base
  has_many :booking_coupons, class_name: 'BookingCoupon', dependent: :destroy
  has_many :bookings, through: :booking_coupons

  validates_uniqueness_of :code
end

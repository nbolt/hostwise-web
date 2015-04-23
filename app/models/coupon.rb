class Coupon < ActiveRecord::Base
  has_many :booking_coupons, class_name: 'BookingCoupon', dependent: :destroy
  has_many :bookings, through: :booking_coupons

  validates_uniqueness_of :code

  as_enum :status, deactivated: 0, active: 1
  as_enum :discount_type, dollar: 0, percentage: 1

  def display_amount
    case discount_type_cd
    when 0
      "$ #{amount/100.0}"
    when 1
      "% #{amount}"
    end
  end
end

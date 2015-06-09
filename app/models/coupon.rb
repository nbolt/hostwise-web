class Coupon < ActiveRecord::Base
  has_many :booking_coupons, class_name: 'BookingCoupon', dependent: :destroy
  has_many :bookings, through: :booking_coupons
  has_many :coupon_users, class_name: 'CouponUser', dependent: :destroy
  has_many :users, through: :coupon_users

  validates_uniqueness_of :code

  as_enum :status, deactivated: 0, active: 1
  as_enum :discount_type, dollar: 0, percentage: 1

  def display_amount
    case discount_type_cd
    when 0
      num = amount / 100.0
      num = '%.2f' % num unless num % 1 == 0
      num = num.to_i     if     num % 1 == 0
      "$ #{num}"
    when 1
      num = amount
      num = '%.2f' % num unless num % 1 == 0
      num = num.to_i     if     num % 1 == 0
      "#{num} %"
    end
  end

  def applied user
    user.coupons.select{|c| c == self}.count
  end

  def total_applied
    bookings.completed.count
  end
end

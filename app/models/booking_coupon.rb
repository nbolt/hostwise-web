class BookingCoupon < ActiveRecord::Base
  belongs_to :booking
  belongs_to :coupon
end

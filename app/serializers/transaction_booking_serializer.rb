class TransactionBookingSerializer < ActiveModel::Serializer
  attributes :id, :date, :cost, :first_booking_discount, :first_booking_discount_cost, :coupon_cost, :discounted, :discounted_cost,
             :refunded, :refunded_cost, :extra_king_sets, :extra_king_sets_cost, :extra_twin_sets, :extra_twin_sets_cost,
             :extra_toiletry_sets, :extra_toiletry_sets_cost, :late_next_day, :late_same_day, :late_next_day_cost, :preset_cost,
             :late_same_day_cost, :overage, :overage_cost, :extra_instructions, :cleaning_cost, :linen_cost, :linens_cost, :toiletries_cost,
             :pool_cost, :patio_cost, :windows_cost, :staging_cost, :no_access_fee_cost, :late_next_day_cost, :late_same_day_cost

  has_one :payment
  has_one :property
  has_many :services
end

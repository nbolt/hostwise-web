class AddCouponCostToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :coupon_cost, :integer, default: 0
  end
end

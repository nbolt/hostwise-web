class AddCostToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :cleaning_cost, :integer, default: 0
    add_column :bookings, :linen_cost, :integer, default: 0
    add_column :bookings, :toiletries_cost, :integer, default: 0
    add_column :bookings, :pool_cost, :integer, default: 0
    add_column :bookings, :patio_cost, :integer, default: 0
    add_column :bookings, :windows_cost, :integer, default: 0
    add_column :bookings, :staging_cost, :integer, default: 0
    add_column :bookings, :no_access_fee_cost, :integer, default: 0
    add_column :bookings, :late_next_day_cost, :integer, default: 0
    add_column :bookings, :late_same_day_cost, :integer, default: 0
    add_column :bookings, :first_booking_discount_cost, :integer, default: 0
  end
end

class AddDiscountToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :first_booking_discount, :boolean, default: false
  end
end

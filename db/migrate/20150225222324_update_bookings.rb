class UpdateBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :late_next_day, :boolean, default: false
    add_column :bookings, :late_same_day, :boolean, default: false
  end
end

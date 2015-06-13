class AddAdminToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :admin, :boolean, default: false
  end
end

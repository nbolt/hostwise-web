class AddAccessToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :no_access_fee, :boolean
  end
end

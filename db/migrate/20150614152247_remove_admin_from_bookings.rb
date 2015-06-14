class RemoveAdminFromBookings < ActiveRecord::Migration
  def change
    remove_column :bookings, :admin, :boolean
  end
end

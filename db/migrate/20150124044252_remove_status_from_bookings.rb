class RemoveStatusFromBookings < ActiveRecord::Migration
  def change
    remove_column :bookings, :status, :string
  end
end

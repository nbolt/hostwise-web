class AddStatusCdToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :status_cd, :integer
  end
end

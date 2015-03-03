class AddDefaultToBookings < ActiveRecord::Migration
  def change
    change_column_default :bookings, :status_cd, 1
  end
end

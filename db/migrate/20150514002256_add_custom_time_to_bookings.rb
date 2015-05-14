class AddCustomTimeToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :custom_timeslot, :string
  end
end

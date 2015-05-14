class AddTimeToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :timeslot, :string, default: 'flex'
  end
end

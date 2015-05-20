class AddNewTimeslotToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :timeslot, :integer
    add_column :bookings, :timeslot_type_cd, :integer
  end
end

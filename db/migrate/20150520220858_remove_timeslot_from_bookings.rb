class RemoveTimeslotFromBookings < ActiveRecord::Migration
  def change
    remove_column :bookings, :custom_timeslot, :string
    remove_column :bookings, :timeslot, :string
  end
end

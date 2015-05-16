class AddTimeslotCostToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :timeslot_cost, :integer
  end
end

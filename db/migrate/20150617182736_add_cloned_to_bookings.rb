class AddClonedToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :cloned, :boolean, default: false
  end
end

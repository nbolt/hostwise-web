class AddLinenHandlingToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :linen_handling_cd, :integer
    add_column :properties, :linen_handling_cd, :integer
  end
end

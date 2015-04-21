class AddExtraCostsToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :extra_king_sets_cost, :integer, default: 0
    add_column :bookings, :extra_twin_sets_cost, :integer, default: 0
    add_column :bookings, :extra_toiletry_sets_cost, :integer, default: 0
  end
end

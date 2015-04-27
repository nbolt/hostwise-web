class AddExtrasToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :extra_king_sets, :integer, default: 0
    add_column :bookings, :extra_twin_sets, :integer, default: 0
    add_column :bookings, :extra_toiletry_sets, :integer, default: 0
    add_column :bookings, :extra_instructions, :string, default: ''
  end
end

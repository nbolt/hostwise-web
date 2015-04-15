class AddAdjustedToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :adjusted, :boolean, default: false
    add_column :bookings, :overage, :boolean, default: false
    add_column :bookings, :discounted, :boolean, default: false
    add_column :bookings, :adjusted_cost, :integer, default: 0
    add_column :bookings, :overage_cost, :integer, default: 0
    add_column :bookings, :discounted_cost, :integer, default: 0
  end
end

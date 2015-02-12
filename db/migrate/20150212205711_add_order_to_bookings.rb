class AddOrderToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :balanced_order_id, :string
  end
end

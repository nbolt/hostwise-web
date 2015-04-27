class AddRefundedToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :refunded, :boolean, default: false
    add_column :bookings, :refunded_cost, :integer, default: 0
    add_column :bookings, :refunded_reason, :string
  end
end

class AddReasonsToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :discounted_reason, :string, default: ''
    add_column :bookings, :overage_reason, :string, default: ''
  end
end

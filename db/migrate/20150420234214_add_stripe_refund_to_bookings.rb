class AddStripeRefundToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :stripe_refund_id, :string
  end
end

class AddPaymentStatusToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :payment_status_cd, :integer, default: 0
  end
end

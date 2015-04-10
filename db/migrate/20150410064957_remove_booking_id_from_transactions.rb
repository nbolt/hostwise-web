class RemoveBookingIdFromTransactions < ActiveRecord::Migration
  def change
    remove_column :transactions, :booking_id, :integer
  end
end

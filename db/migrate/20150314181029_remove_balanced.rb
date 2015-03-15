class RemoveBalanced < ActiveRecord::Migration
  def change
    remove_column :bookings, :balanced_order_id, :string
    remove_column :payments, :balanced_id, :string
    remove_column :payments, :balanced_verification_id, :string
    remove_column :transactions, :balanced_charge_id, :string
    remove_column :users, :balanced_customer_id, :string
    remove_column :payments, :bank_name, :string
    remove_column :payments, :holder_name, :string
  end
end

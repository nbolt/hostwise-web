class AddPayoutToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :payout, :boolean, default: false
  end
end

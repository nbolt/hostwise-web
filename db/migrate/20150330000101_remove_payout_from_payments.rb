class RemovePayoutFromPayments < ActiveRecord::Migration
  def change
    remove_column :payments, :payout, :boolean
  end
end

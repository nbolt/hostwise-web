class AddTransferIdToPayouts < ActiveRecord::Migration
  def change
    add_column :payouts, :stripe_transfer_id, :string
  end
end

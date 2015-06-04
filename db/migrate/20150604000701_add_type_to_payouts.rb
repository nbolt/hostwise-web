class AddTypeToPayouts < ActiveRecord::Migration
  def change
    add_column :payouts, :payout_type_cd, :integer
  end
end

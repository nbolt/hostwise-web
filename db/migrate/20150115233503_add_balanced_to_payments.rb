class AddBalancedToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :balanced_id, :string
  end
end

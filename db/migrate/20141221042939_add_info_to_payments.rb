class AddInfoToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :stripe_id, :string
    add_column :payments, :last4, :string
    add_column :payments, :card_type, :string
    add_column :payments, :fingerprint, :string
  end
end

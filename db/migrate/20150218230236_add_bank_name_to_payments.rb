class AddBankNameToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :bank_name, :string
    add_column :payments, :holder_name, :string
    add_column :payments, :routing_number, :string
  end
end

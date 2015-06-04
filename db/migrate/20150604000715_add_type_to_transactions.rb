class AddTypeToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :transaction_type_cd, :integer
  end
end

class AddChargedAtToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :charged_at, :date
  end
end

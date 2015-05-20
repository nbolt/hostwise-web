class CreatePropertyTransactions < ActiveRecord::Migration
  def change
    create_table :property_transactions do |t|
      t.references :property, index: true, foreign_key: true
      t.integer :stripe_transaction_id

      t.timestamps null: false
    end

    add_foreign_key :property_transactions, :transactions, column: :stripe_transaction_id
    add_index :property_transactions, :stripe_transaction_id
  end
end

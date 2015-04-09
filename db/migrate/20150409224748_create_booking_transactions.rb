class CreateBookingTransactions < ActiveRecord::Migration
  def change
    create_table :booking_transactions do |t|
      t.references :booking, index: true, foreign_key: true
      t.integer :stripe_transaction_id

      t.timestamps null: false
    end

    add_foreign_key :booking_transactions, :transactions, column: :stripe_transaction_id
    add_index :booking_transactions, :stripe_transaction_id
  end
end

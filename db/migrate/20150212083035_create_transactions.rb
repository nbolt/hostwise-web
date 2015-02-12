class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string :stripe_charge_id
      t.string :balanced_charge_id
      t.integer :status_cd
      t.string :failure_message
      t.references :booking, index: true

      t.timestamps null: false
    end
    add_foreign_key :transactions, :bookings
  end
end

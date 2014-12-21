class CreateBookings < ActiveRecord::Migration
  def change
    create_table :bookings do |t|
      t.references :property, index: true
      t.references :payment, index: true
      t.datetime :date

      t.timestamps null: false
    end
    add_foreign_key :bookings, :properties
    add_foreign_key :bookings, :payments
  end
end

class CreateBookingUsers < ActiveRecord::Migration
  def change
    create_table :booking_users do |t|
      t.references :booking, index: true
      t.references :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :booking_users, :bookings
    add_foreign_key :booking_users, :users
  end
end

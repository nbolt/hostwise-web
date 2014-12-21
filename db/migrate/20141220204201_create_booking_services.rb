class CreateBookingServices < ActiveRecord::Migration
  def change
    create_table :booking_services do |t|
      t.references :booking, index: true
      t.references :service, index: true

      t.timestamps null: false
    end
    add_foreign_key :booking_services, :bookings
    add_foreign_key :booking_services, :services
  end
end

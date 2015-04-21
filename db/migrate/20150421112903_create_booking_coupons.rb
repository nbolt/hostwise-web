class CreateBookingCoupons < ActiveRecord::Migration
  def change
    create_table :booking_coupons do |t|
      t.references :booking, index: true, foreign_key: true
      t.references :coupon, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end

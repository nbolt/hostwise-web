class CreateCouponUsers < ActiveRecord::Migration
  def change
    create_table :coupon_users do |t|
      t.references :coupon, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end

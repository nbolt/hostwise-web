class CreateCoupons < ActiveRecord::Migration
  def change
    create_table :coupons do |t|
      t.string :description
      t.string :code
      t.integer :status_cd, default: 1
      t.integer :amount, default: 0
      t.integer :limit, default: 0
      t.date :expiration
      t.integer :discount_type_cd, default: 0

      t.timestamps null: false
    end
  end
end

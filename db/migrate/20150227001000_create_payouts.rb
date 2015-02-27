class CreatePayouts < ActiveRecord::Migration
  def change
    create_table :payouts do |t|
      t.integer :user_id
      t.integer :job_id
      t.integer :status_cd, default: 0
      t.integer :amount

      t.timestamps null: false
    end
  end
end

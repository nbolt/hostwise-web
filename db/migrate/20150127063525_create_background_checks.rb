class CreateBackgroundChecks < ActiveRecord::Migration
  def change
    create_table :background_checks do |t|
      t.references :user, index: true
      t.string :order_id
      t.integer :status_cd

      t.timestamps null: false
    end
    add_foreign_key :background_checks, :users
  end
end

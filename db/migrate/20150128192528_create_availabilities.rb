class CreateAvailabilities < ActiveRecord::Migration
  def change
    create_table :availabilities do |t|
      t.references :user, index: true

      t.boolean :mon, default: false
      t.boolean :tues, default: false
      t.boolean :wed, default: false
      t.boolean :thurs, default: false
      t.boolean :fri, default: false
      t.boolean :sat, default: false
      t.boolean :sun, default: false

      t.timestamps null: false
    end
    add_foreign_key :availabilities, :users
  end
end

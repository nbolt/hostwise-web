class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.integer :status_cd
      t.integer :booking_id

      t.timestamps null: false
    end
  end
end

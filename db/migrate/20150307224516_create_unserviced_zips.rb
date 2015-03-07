class CreateUnservicedZips < ActiveRecord::Migration
  def change
    create_table :unserviced_zips do |t|
      t.string :email
      t.string :code

      t.timestamps null: false
    end
  end
end

class CreateDistributionCenters < ActiveRecord::Migration
  def change
    create_table :distribution_centers do |t|
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.float :lat
      t.float :lng

      t.timestamps null: false
    end
  end
end

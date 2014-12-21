class CreateProperties < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.references :user
      t.string :title
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.string :property_type

      t.timestamps
    end
  end
end

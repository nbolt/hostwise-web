class CreatePropertyPhotos < ActiveRecord::Migration
  def change
    create_table :property_photos do |t|
      t.string :photo
      t.integer :property_id

      t.timestamps null: false
    end
  end
end

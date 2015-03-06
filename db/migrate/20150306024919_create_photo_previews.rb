class CreatePhotoPreviews < ActiveRecord::Migration
  def change
    create_table :photo_previews do |t|
      t.string :photo

      t.timestamps null: false
    end
  end
end

class CreateContractorPhotos < ActiveRecord::Migration
  def change
    create_table :contractor_photos do |t|
      t.string :photo
      t.references :checklist, index: true

      t.timestamps null: false
    end
    add_foreign_key :contractor_photos, :checklists
  end
end

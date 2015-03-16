class CreateChecklists < ActiveRecord::Migration
  def change
    create_table :checklists do |t|
      t.references :contractor_job, index: true
      t.boolean :cleaning, default: false
      t.string  :kitchen_photo
      t.string  :bedroom_photo
      t.string  :bathroom_photo

      t.timestamps null: false
    end
    add_foreign_key :checklists, :contractor_jobs
  end
end

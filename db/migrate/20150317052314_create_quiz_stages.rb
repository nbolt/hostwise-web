class CreateQuizStages < ActiveRecord::Migration
  def change
    create_table :quiz_stages do |t|
      t.references :contractor_profile
      t.integer :took_at
      t.integer :score
      t.boolean :pass
      t.timestamps
    end
  end
end

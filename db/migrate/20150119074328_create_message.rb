class CreateMessage < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.references :user
      t.string :body

      t.timestamps
    end
  end
end

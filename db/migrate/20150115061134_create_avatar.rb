class CreateAvatar < ActiveRecord::Migration
  def change
    create_table :avatars do |t|
      t.string :photo
      t.integer :user_id

      t.timestamps null: false
    end
  end
end

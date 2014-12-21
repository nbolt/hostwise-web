class CreateCounties < ActiveRecord::Migration
  def change
    create_table :counties do |t|
      t.references :state, index: true
      t.string :name

      t.timestamps
    end
  end
end

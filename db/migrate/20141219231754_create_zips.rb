class CreateZips < ActiveRecord::Migration
  def change
    create_table :zips do |t|
      t.references :city, index: true
      t.string :code

      t.timestamps
    end
  end
end

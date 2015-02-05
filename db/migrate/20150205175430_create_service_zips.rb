class CreateServiceZips < ActiveRecord::Migration
  def change
    create_table :service_zips do |t|
      t.string :zip

      t.timestamps
    end
  end
end

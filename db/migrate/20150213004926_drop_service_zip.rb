class DropServiceZip < ActiveRecord::Migration
  def change
    drop_table :service_zips
  end
end

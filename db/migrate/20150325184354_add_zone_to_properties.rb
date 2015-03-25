class AddZoneToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :zone, :string
  end
end

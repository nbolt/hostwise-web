class AddRoomsToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :bedrooms, :integer
    add_column :properties, :beds, :integer
    add_column :properties, :accommodates, :integer
  end
end

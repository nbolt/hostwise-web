class RenameAccommodatesToTwinBeds < ActiveRecord::Migration
  def change
    rename_column :properties, :accommodates, :twin_beds
    add_column :properties, :full_beds, :integer
    add_column :properties, :queen_beds, :integer
    add_column :properties, :king_beds, :integer
  end
end

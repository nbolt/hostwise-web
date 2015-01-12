class RenameBedsToBathrooms < ActiveRecord::Migration
  def change
    rename_column :properties, :beds, :bathrooms
  end
end

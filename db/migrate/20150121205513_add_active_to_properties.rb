class AddActiveToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :active, :boolean, default: false
  end
end

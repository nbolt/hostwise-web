class RemovePropertyTypeFromProperties < ActiveRecord::Migration
  def change
    remove_column :properties, :property_type, :string
  end
end

class AddPropertyTypeCdToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :property_type_cd, :integer
  end
end

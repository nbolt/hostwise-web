class AddMoreFieldsToBots < ActiveRecord::Migration
  def change
    add_column :bots, :address, :string
    add_column :bots, :property_type, :string
    add_column :bots, :num_bedrooms, :integer, default: 0
    add_column :bots, :num_bathrooms, :integer, default: 0
    add_column :bots, :num_beds, :integer, default: 0
  end
end

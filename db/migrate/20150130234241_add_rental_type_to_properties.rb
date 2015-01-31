class AddRentalTypeToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :rental_type, :string
  end
end

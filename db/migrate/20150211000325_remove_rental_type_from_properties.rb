class RemoveRentalTypeFromProperties < ActiveRecord::Migration
  def change
    remove_column :properties, :rental_type, :string
  end
end

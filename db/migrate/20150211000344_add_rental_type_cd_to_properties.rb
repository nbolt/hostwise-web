class AddRentalTypeCdToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :rental_type_cd, :integer
  end
end

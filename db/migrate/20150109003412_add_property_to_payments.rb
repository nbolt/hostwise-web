class AddPropertyToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :property_id, :integer
  end
end

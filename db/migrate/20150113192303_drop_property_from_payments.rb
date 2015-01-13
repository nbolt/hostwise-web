class DropPropertyFromPayments < ActiveRecord::Migration
  def change
    remove_column :payments, :property_id
  end
end

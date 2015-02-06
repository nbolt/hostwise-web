class AddDefaultToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :primary, :boolean, default: false
  end
end

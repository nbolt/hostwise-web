class AddPurchaseDateToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :purchase_date, :date
  end
end

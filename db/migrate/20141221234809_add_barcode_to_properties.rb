class AddBarcodeToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :delivery_point_barcode, :string
  end
end

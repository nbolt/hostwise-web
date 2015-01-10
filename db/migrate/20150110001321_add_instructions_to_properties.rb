class AddInstructionsToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :access_info, :string
    add_column :properties, :parking_info, :string
    add_column :properties, :additional_info, :string
    add_column :properties, :trash_disposal, :string
  end
end

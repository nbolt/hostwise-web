class AddRestockingInstructionToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :restocking_info, :string
  end
end

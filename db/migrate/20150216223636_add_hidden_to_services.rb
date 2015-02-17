class AddHiddenToServices < ActiveRecord::Migration
  def change
    add_column :services, :hidden, :boolean, default: false
  end
end

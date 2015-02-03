class AddDisplayToServices < ActiveRecord::Migration
  def change
    add_column :services, :display, :string
  end
end

class AddExtraToServices < ActiveRecord::Migration
  def change
    add_column :services, :extra, :boolean
  end
end

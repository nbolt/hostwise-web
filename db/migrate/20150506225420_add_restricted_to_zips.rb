class AddRestrictedToZips < ActiveRecord::Migration
  def change
    add_column :zips, :restricted, :boolean, default: false
  end
end

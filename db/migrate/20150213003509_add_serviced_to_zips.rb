class AddServicedToZips < ActiveRecord::Migration
  def change
    add_column :zips, :serviced, :boolean, default: false
  end
end

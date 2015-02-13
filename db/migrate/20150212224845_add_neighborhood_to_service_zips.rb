class AddNeighborhoodToServiceZips < ActiveRecord::Migration
  def change
    add_column :service_zips, :neighborhood_id, :integer
  end
end

class AddZoneToDistributionCenters < ActiveRecord::Migration
  def change
    add_column :distribution_centers, :zone, :string
  end
end

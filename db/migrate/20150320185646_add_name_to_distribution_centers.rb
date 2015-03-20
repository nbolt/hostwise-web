class AddNameToDistributionCenters < ActiveRecord::Migration
  def change
    add_column :distribution_centers, :name, :string
  end
end

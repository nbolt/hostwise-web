class AddStatusCdToDistributionCenters < ActiveRecord::Migration
  def change
    add_column :distribution_centers, :status_cd, :integer
  end
end

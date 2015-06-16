class AddMarketIdToDistributionCenters < ActiveRecord::Migration
  def change
    add_reference :distribution_centers, :market, index: true, foreign_key: true
  end
end

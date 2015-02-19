class AddDistributionToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :distribution, :boolean, default: false
  end
end

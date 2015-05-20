class RemoveDistributionTimeslotFromJobs < ActiveRecord::Migration
  def change
    remove_column :jobs, :distribution_timeslot, :string
  end
end

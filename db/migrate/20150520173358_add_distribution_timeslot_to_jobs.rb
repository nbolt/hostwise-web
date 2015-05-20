class AddDistributionTimeslotToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :distribution_timeslot, :string
  end
end

class AddNewTimeslotToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :distribution_timeslot, :integer
  end
end

class AddManHoursToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :man_hours, :float
  end
end

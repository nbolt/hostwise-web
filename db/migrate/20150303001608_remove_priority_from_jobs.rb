class RemovePriorityFromJobs < ActiveRecord::Migration
  def change
    remove_column :jobs, :priority, :integer
  end
end

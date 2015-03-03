class AddPriorityToContractorJobs < ActiveRecord::Migration
  def change
    add_column :contractor_jobs, :priority, :integer, default: 0
  end
end

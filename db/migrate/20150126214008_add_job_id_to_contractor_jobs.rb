class AddJobIdToContractorJobs < ActiveRecord::Migration
  def change
    add_column :contractor_jobs, :job_id, :integer
  end
end

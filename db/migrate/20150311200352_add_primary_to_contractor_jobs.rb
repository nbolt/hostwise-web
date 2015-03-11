class AddPrimaryToContractorJobs < ActiveRecord::Migration
  def change
    add_column :contractor_jobs, :primary, :boolean, default: false
  end
end

class CreateJobDistributionCenters < ActiveRecord::Migration
  def change
    create_table :job_distribution_centers do |t|
      t.references :job, index: true
      t.references :distribution_center, index: true

      t.timestamps null: false
    end
    add_foreign_key :job_distribution_centers, :jobs
    add_foreign_key :job_distribution_centers, :distribution_centers
  end
end

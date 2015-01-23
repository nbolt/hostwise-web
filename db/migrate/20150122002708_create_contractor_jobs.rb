class CreateContractorJobs < ActiveRecord::Migration
  def change
    create_table :contractor_jobs do |t|
      t.references :booking, index: true
      t.references :user, index: true

      t.timestamps null: false
    end
    add_foreign_key :contractor_jobs, :bookings
    add_foreign_key :contractor_jobs, :users
  end
end

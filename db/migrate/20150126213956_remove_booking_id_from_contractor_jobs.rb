class RemoveBookingIdFromContractorJobs < ActiveRecord::Migration
  def change
    remove_column :contractor_jobs, :booking_id, :integer
  end
end

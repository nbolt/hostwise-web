class AddToiletriesToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :toiletries, :integer
  end
end

class AddOccasionToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :occasion_cd, :integer
  end
end

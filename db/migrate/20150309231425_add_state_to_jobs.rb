class AddStateToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :state_cd, :integer, default: 0
  end
end

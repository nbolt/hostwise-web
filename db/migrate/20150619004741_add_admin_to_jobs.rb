class AddAdminToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :admin_set, :boolean, default: false
  end
end

class AddCantAccessToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :cant_access, :datetime
  end
end

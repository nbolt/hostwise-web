class AddSizeToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :size, :integer, default: 1
  end
end

class AddBedsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :king_beds, :integer
    add_column :jobs, :queen_beds, :integer
    add_column :jobs, :full_beds, :integer
    add_column :jobs, :twin_beds, :integer
  end
end

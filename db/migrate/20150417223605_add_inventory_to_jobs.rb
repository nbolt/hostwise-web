class AddInventoryToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :king_sheets, :integer, default: 0
    add_column :jobs, :twin_sheets, :integer, default: 0
    add_column :jobs, :pillow_count, :integer, default: 0
    add_column :jobs, :bath_towels, :integer, default: 0
    add_column :jobs, :hand_towels, :integer, default: 0
    add_column :jobs, :face_towels, :integer, default: 0
    add_column :jobs, :bath_mats, :integer, default: 0
  end
end

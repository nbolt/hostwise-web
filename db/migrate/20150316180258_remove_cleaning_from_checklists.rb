class RemoveCleaningFromChecklists < ActiveRecord::Migration
  def change
    remove_column :checklists, :cleaning, :boolean
  end
end

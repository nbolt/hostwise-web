class RemoveStatusCdFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :status_cd, :integer
  end
end

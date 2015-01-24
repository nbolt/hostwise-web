class DropStatusFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :status_cd
  end
end

class UpdateRoleOnUsers < ActiveRecord::Migration
  def change
    remove_column :users, :role
    add_column :users, :role_cd, :integer
  end
end

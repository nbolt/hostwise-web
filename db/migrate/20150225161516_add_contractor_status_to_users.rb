class AddContractorStatusToUsers < ActiveRecord::Migration
  def change
    add_column :users, :status_cd, :integer, default: 1
  end
end

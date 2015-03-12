class AddVipToUsers < ActiveRecord::Migration
  def change
    add_column :users, :vip_count, :integer, default: 0
  end
end

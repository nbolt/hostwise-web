class AddCountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :booking_count, :integer
  end
end

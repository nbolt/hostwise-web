class AddAppliedToCoupons < ActiveRecord::Migration
  def change
    add_column :coupons, :applied, :integer, default: 0
  end
end

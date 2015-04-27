class RemoveAppliedFromCoupons < ActiveRecord::Migration
  def change
    remove_column :coupons, :applied, :boolean
  end
end

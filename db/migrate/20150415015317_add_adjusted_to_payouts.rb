class AddAdjustedToPayouts < ActiveRecord::Migration
  def change
    add_column :payouts, :adjusted, :boolean, default: false
    add_column :payouts, :addition, :boolean, default: false
    add_column :payouts, :subtraction, :boolean, default: false
    add_column :payouts, :adjusted_amount, :integer, default: 0
    add_column :payouts, :additional_amount, :integer, default: 0
    add_column :payouts, :subtracted_amount, :integer, default: 0
  end
end

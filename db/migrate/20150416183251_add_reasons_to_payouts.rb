class AddReasonsToPayouts < ActiveRecord::Migration
  def change
    add_column :payouts, :subtracted_reason, :string, default: ''
    add_column :payouts, :additional_reason, :string, default: ''
  end
end

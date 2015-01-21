class AddStatusToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :status_cd, :integer
  end
end

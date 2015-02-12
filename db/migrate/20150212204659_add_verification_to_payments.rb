class AddVerificationToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :balanced_verification_id, :string
  end
end

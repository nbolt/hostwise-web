class AddConfirmationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :phone_confirmation, :string
  end
end

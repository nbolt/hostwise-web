class AddSourceToBotAccounts < ActiveRecord::Migration
  def change
    add_column :bot_accounts, :source_cd, :integer
  end
end

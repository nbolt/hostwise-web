class UpdateStatusForBotAccounts < ActiveRecord::Migration
  def change
    change_column :bot_accounts, :status_cd, 'integer USING CAST(status_cd AS integer)'
  end
end

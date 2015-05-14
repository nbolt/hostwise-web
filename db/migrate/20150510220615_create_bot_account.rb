class CreateBotAccount < ActiveRecord::Migration
  def change
    create_table :bot_accounts do |t|
      t.string :email
      t.string :password
      t.string :status_cd
      t.date :last_run

      t.timestamps null: false
    end
  end
end

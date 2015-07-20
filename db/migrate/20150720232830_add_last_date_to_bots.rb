class AddLastDateToBots < ActiveRecord::Migration
  def change
    add_column :bots, :last_sms, :date
  end
end

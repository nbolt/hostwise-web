class AddLastDateToBots < ActiveRecord::Migration
  def change
    add_column :bots, :last_contacted, :date
  end
end

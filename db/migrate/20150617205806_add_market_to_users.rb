class AddMarketToUsers < ActiveRecord::Migration
  def change
    add_reference :users, :market, index: true, foreign_key: true
  end
end

class AddMarketToZipCodes < ActiveRecord::Migration
  def change
    add_reference :zips, :market, index: true, foreign_key: true
  end
end

class AddZipsToProperties < ActiveRecord::Migration
  def change
    add_reference :properties, :zip, index: true, foreign_key: true
  end
end

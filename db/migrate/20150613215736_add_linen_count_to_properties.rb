class AddLinenCountToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :linen_count, :integer, default: 0
  end
end

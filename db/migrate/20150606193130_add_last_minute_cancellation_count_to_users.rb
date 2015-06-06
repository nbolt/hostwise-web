class AddLastMinuteCancellationCountToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_minute_cancellation_count, :integer, default: 0
  end
end

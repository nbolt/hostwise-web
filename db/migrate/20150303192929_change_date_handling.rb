class ChangeDateHandling < ActiveRecord::Migration
  def change
    change_column :jobs, :date, :date
    change_column :bookings, :date, :date
  end
end

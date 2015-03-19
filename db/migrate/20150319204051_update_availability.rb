class UpdateAvailability < ActiveRecord::Migration
  def change
    change_column :availabilities, :mon, :boolean, default: false
    change_column :availabilities, :tues, :boolean, default: false
    change_column :availabilities, :wed, :boolean, default: false
    change_column :availabilities, :thurs, :boolean, default: false
    change_column :availabilities, :fri, :boolean, default: false
    change_column :availabilities, :sat, :boolean, default: false
    change_column :availabilities, :sun, :boolean, default: false
  end
end

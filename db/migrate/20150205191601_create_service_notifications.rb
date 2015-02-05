class CreateServiceNotifications < ActiveRecord::Migration
  def change
    create_table :service_notifications do |t|
      t.references :user, index: true
      t.string :zip

      t.timestamps
    end
    add_foreign_key :service_notifications, :users
  end
end

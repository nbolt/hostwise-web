class CreateBot < ActiveRecord::Migration
  def change
    create_table :bots do |t|
      t.string :host_name
      t.string :profile_id
      t.string :profile_url
      t.string :property_id
      t.string :property_name
      t.string :property_url
      t.integer :status_cd
      t.integer :source_cd
      t.boolean :super_host

      t.timestamps null: false
    end
  end
end

class CreateContractorProfile < ActiveRecord::Migration
  def change
    create_table :contractor_profiles do |t|
      t.references :user
      t.integer :position_cd
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.string :emergency_contact_phone
      t.string :emergency_contact_first_name
      t.string :emergency_contact_last_name

      t.timestamps
    end
  end
end

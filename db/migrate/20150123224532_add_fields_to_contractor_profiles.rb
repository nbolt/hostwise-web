class AddFieldsToContractorProfiles < ActiveRecord::Migration
  def change
    add_column :contractor_profiles, :ssn, :string
    add_column :contractor_profiles, :dob, :string
    add_column :contractor_profiles, :driver_license, :string
    add_column :contractor_profiles, :delivery_point_barcode, :string
  end
end

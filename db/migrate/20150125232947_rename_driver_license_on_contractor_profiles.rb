class RenameDriverLicenseOnContractorProfiles < ActiveRecord::Migration
  def change
    rename_column :contractor_profiles, :driver_license, :encrypted_driver_license
  end
end

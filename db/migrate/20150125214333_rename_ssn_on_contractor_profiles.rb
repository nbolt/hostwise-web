class RenameSsnOnContractorProfiles < ActiveRecord::Migration
  def change
    rename_column :contractor_profiles, :ssn, :encrypted_ssn
  end
end

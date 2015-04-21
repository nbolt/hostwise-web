class AddVerifiedToContractorProfiles < ActiveRecord::Migration
  def change
    add_column :contractor_profiles, :verified, :boolean, default: false
  end
end

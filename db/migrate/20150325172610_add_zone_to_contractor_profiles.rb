class AddZoneToContractorProfiles < ActiveRecord::Migration
  def change
    add_column :contractor_profiles, :zone, :string
  end
end

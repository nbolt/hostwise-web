class AddLatLngToContractorProfiles < ActiveRecord::Migration
  def change
    add_column :contractor_profiles, :lat, :float
    add_column :contractor_profiles, :lng, :float
  end
end

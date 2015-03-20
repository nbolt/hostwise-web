class AddDocusignToContractorProfiles < ActiveRecord::Migration
  def change
    add_column :contractor_profiles, :docusign_completed, :boolean
    add_column :contractor_profiles, :docusign_id, :string
  end
end

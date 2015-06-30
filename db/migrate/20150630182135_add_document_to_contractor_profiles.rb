class AddDocumentToContractorProfiles < ActiveRecord::Migration
  def change
    add_column :contractor_profiles, :document, :string
  end
end

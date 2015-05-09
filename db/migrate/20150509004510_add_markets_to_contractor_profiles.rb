class AddMarketsToContractorProfiles < ActiveRecord::Migration
  def change
    add_reference :contractor_profiles, :market, index: true, foreign_key: true
  end
end

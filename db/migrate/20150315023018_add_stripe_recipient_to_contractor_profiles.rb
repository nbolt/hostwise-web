class AddStripeRecipientToContractorProfiles < ActiveRecord::Migration
  def change
    add_column :contractor_profiles, :stripe_recipient_id, :string
  end
end

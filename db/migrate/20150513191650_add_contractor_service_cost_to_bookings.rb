class AddContractorServiceCostToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :contractor_service_cost, :integer, default: 0
  end
end

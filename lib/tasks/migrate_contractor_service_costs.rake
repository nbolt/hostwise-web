namespace :migrate do
  task contractor_service_costs: :environment do
    Booking.where.not(status_cd: 1).each do |booking|
      booking.update_attribute :contractor_service_cost, [booking.cleaning_cost, booking.pool_cost, booking.patio_cost, booking.windows_cost, booking.preset_cost].sum
    end
  end
end

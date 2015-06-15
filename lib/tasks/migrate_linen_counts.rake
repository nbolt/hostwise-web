namespace :migrate do
  task linen_counts: :environment do
    Property.all.each do |property|
      property.update_attribute :linen_count, property.last_booking.linen_set_count if property.last_booking
    end
  end
end

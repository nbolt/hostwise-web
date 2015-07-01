module CsvHelper
  include ActionView::Helpers::NumberHelper
  include Admin::JobsHelper

  def transaction_csv(results)
    CSV.generate do |csv|
      csv << %w(Date Property Services Payment Total)
      results.each do |booking|
        #booking = transaction.bookings.find {|booking| booking.user.id == current_user.id}
        csv << [booking.date.strftime('%m/%d/%Y'),
                booking.property.nickname,
                booking.services.collect{|s| s.display}.join(','),
                "**** #{booking.payment.last4}",
                "#{number_to_currency(booking.cost, precision: 2)}"]
      end
    end
  end

  def job_csv(results)
    CSV.generate do |csv|
      csv << ['ID', 'Property', 'Size', 'Date Booked', 'Service Date', 'Nickname', 'Address', 'Customer', 'Customer Email', 'Phone', 'Status', 'Cost', 'Services', 'King Set(s)', 'Twin Set(s)', 'Toiletries Set(s)', 'Contractor(s)', 'Type']
      results.each do |job|
        csv << [job.id, property_id(job), bed_bath(job), date_booked(job), job.date, job.booking.property.nickname, address(job), host(job), host_email(job), phone_number(job), job.status, cost(job), service_list(job), king_sets(job), twin_sets(job), bathrooms(job), job.contractor_names, job.state]
      end
    end
  end

  def host_csv(results)
    CSV.generate do |csv|
      csv << ['ID', 'Name', 'Joined', 'Email', 'Phone', 'Status', 'Properties', 'Completed Jobs', 'Upcoming Jobs', 'Next Service', 'Total Spent']
      results.each do |host|
        csv << [host.id, host.name, host.created_at, host.email, host.display_phone_number, host.status, host.property_count, host.completed_jobs_count, host.upcoming_jobs_count, host.next_service_date, host.total_spent]
      end
    end
  end

  def contractor_csv(results)
    CSV.generate do |csv|
      csv << ['ID', 'Name', 'Joined', 'City', 'Market', 'Email', 'Phone', 'Position', 'Status', 'Contract Signed', 'BGC Status']
      results.each do |contractor|
        csv << [contractor.id, contractor.name, contractor.created_at, contractor.contractor_profile.then(:city), contractor.contractor_profile.chain(:market, :name), contractor.email, contractor.display_phone_number, contractor.contractor_profile.then(:position), contractor.status, contractor.contractor_profile.then(:docusign_completed), contractor.background_check.then(:status)]
      end
    end
  end

  def property_csv(results)
    CSV.generate do |csv|
      csv << ['ID', 'Nickname', 'Customer', 'Address', 'Type', 'Linen', 'Last Service', 'Next Service', 'Service Completed', 'Total Revenue', 'King Beds', 'Queen Beds', 'Full Beds', 'Twin Beds']
      results.each do |property|
        csv << [property.id, property.nickname, property.user.name, property.neighborhood_address, property.property_type, property.linen_handling, property.last_service_date, property.next_service_date, property.bookings.where(status_cd: 3).count, property.bookings.where(status_cd: [3,5]).reduce(0) {|a,b| a + b.cost}, property.king_beds, property.queen_beds, property.full_beds, property.twin_beds]
      end
    end
  end

  def coupon_csv(results)
    CSV.generate do |csv|
      csv << ['ID', 'Description', 'Code', 'Status', 'Discount Type', 'Amount', 'Expiration', 'Limit', 'Applied']
      results.each do |coupon|
        csv << [coupon.id, coupon.description, coupon.code, coupon.status, coupon.discount_type, coupon.amount / 100.0, coupon.expiration, coupon.limit, coupon.total_applied]
      end
    end
  end
end

module CsvHelper
  include ActionView::Helpers::NumberHelper
  include Admin::JobsHelper

  def transaction_csv(results)
    CSV.generate do |csv|
      csv << %w(Date Properties Payment Total)
      results.each do |transaction|
        csv << [transaction.created_at.to_date, transaction.bookings.map{|b| b.property.nickname}.join(', '), transaction.bookings.first.payment.display, transaction.amount / 100.0]
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
      csv << ['ID', 'Description', 'Code', 'Status', 'Discount Type', 'Amount', 'Expiration', 'Limit', 'Applied - Projected', 'Applied - Completed']
      results.each do |coupon|
        csv << [coupon.id, coupon.description, coupon.code, coupon.status, coupon.discount_type, coupon.amount / 100.0, coupon.expiration, coupon.limit, coupon.total_applied_projected, coupon.total_applied]
      end
    end
  end

  def inventory_properties_csv(results)
    CSV.generate do |csv|
      csv << ['ID', 'Nickname', 'Customer', 'Address', 'Linen Count', 'Turnover Rate', 'Last Service', 'Next Service']
      results.each do |property|
        csv << [property.id, property.nickname, property.user.name, property.neighborhood_address, property.linen_count, property.turnover_rate, property.last_service_date, property.next_service_date]
      end
    end
  end

  def inventory_jobs_csv(results)
    CSV.generate do |csv|
      csv << ['ID', 'Nickname', 'Size', 'Address', 'Services', 'Date', 'Contractors', 'King Sheets (new / soiled)', 'Twin Sheets', 'Pillows', 'Bath Towels', 'Bath Mats', 'Hand Towels', 'Face Towels']
      results.each do |job|
        csv << [job.id, job.booking.property.nickname, job.booking.property.property_size, job.booking.property.neighborhood_address, job.booking.service_list, job.date, job.contractor_names, "#{job.king_bed_count} / #{job.soiled_king_count}", "#{job.twin_bed_count} / #{job.soiled_twin_count}", "#{job.pillow_count} / #{job.soiled_pillow_count}", "#{job.bath_towel_count} / #{job.soiled_bath_towel_count}", "#{job.bath_mat_count} / #{job.soiled_mat_count}", "#{job.hand_towel_count} / #{job.soiled_hand_count}", "#{job.face_towel_count} / #{job.soiled_face_count}"]
      end
    end
  end
end

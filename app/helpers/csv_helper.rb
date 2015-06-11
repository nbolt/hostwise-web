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
end

module CsvHelper
  include ActionView::Helpers::NumberHelper

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
end

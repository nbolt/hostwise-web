module CsvHelper
  include ActionView::Helpers::NumberHelper

  def transaction_csv(results)
    CSV.generate do |csv|
      csv << %w(Date Property Services Payment Total)
      results.each do |transaction|
        booking = transaction.booking
        csv << [booking.date.strftime('%m/%d/%Y'),
                booking.property.nickname,
                booking.services.collect{|s| s.display}.join(','),
                "**** #{booking.payment.last4}",
                "#{number_to_currency(transaction.amount / 100, precision: 2)}"]
      end
    end
  end
end

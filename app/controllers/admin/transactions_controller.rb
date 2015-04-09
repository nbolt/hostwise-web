class Admin::TransactionsController < Admin::AuthController
  expose(:transaction) { Transaction.find params[:id] }

  def index
    transactions = Transaction.all

    respond_to do |format|
      format.html
      format.json do
        render json: transactions
      end
    end
  end

  def process_payments
    bookings = params[:bookings].map {|id| Booking.find id}.group_by {|booking| booking.user.id}.map do |user_id, bookings|
      {
        user: User.find(user_id),
        booking_groups: bookings.group_by {|booking| booking.payment.id}.map do |payment_id, bookings|
          {
            payment: Payment.find(payment_id),
            total: bookings.reduce(0) {|acc, booking| acc + booking.cost} * 100,
            bookings: bookings
          }
        end
      }
    end

    bookings.each do |user_bookings|
      user_bookings[:booking_groups].each do |booking_group|
        begin
          metadata = { booking_ids: booking_group[:bookings].map(&:id).to_s }
          rsp = Stripe::Charge.create(
            amount: booking_group[:total],
            currency: 'usd',
            customer: user_bookings[:user].stripe_customer_id,
            source: booking_group[:payment].stripe_id,
            statement_descriptor: "HostWise"[0..21], # 22 characters max
            metadata: metadata
          )
          booking_group[:bookings].each do |booking|
            booking.transactions.create(stripe_charge_id: rsp.id, status_cd: 0, amount: booking.cost * 100)
            booking.save
          end
        rescue Stripe::CardError => e
          err  = e.json_body[:error]
          booking_group[:bookings].each do |booking|
            booking.transactions.create(stripe_charge_id: err[:charge], status_cd: 1, failure_message: err[:message], amount: booking.cost * 100)
          end
          UserMailer.generic_notification("Stripe Payment Failed - ***#{payment.last4}: #{property.user.name}", "Booking ID: #{id}").then(:deliver)
          false
        end
      end
    end
    render json: { success: true }
  end

  def process_payouts
  end

end

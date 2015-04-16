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

  def export
    @bookings = params[:bookings].map {|id| Booking.find id}

    respond_to do |format|
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"bookings.csv\""
        headers['Content-Type'] ||= 'text/csv'
      end
    end
  end

  def process_payments
    successful_payments = []

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
            booking.transactions.create(stripe_charge_id: rsp.id, status_cd: 0, amount: booking_group[:total])
            booking.save
            successful_payments.push booking.id
            UserMailer.service_completed(booking).then(:deliver) if user_bookings[:user].settings(:service_completion).email
          end
        rescue Stripe::CardError => e
          err  = e.json_body[:error]
          booking_group[:bookings].each do |booking|
            booking.transactions.create(stripe_charge_id: err[:charge], status_cd: 1, failure_message: err[:message], amount: booking_group[:total])
          end
          UserMailer.generic_notification("Stripe Payment Failed - ***#{booking_group[:payment].last4}", "Booking IDs: #{booking_group[:bookings].map(&:id).join(', ').to_s}").then(:deliver)
          false
        end
      end
    end
    render json: { success: true, payments: successful_payments }
  end

  def process_payouts
    successful_payouts = []

    jobs = params[:jobs].map {|id| Job.find(id).contractor_jobs}.flatten.group_by(&:user_id).map do |user_id, jobs|
      {
        user: User.find(user_id),
        jobs: jobs.map {|cj| Job.find cj.job_id}
      }
    end

    jobs.each do |user_jobs|
      user = user_jobs[:user]
      if user.chain(:contractor_profile, :stripe_recipient_id)
        total = 0
        payouts = Payout.where(job_id: user_jobs[:jobs].map(&:id), user_id: user.id)

        pending_payouts = payouts.pending
        pending_payouts.each do |payout|
          rsp = Stripe::Transfer.retrieve payout.stripe_transfer_id
          case rsp.status
          when 'paid'
            payout.update_attribute :status_cd, 2
          when 'failed'
            payout.update_attribute :status_cd, 3
          end
        end
        completed_payouts = pending_payouts.select{|payout| payout.status_cd == 2}.sort_by {|payout| payout.job.date}
        completed_payouts.each {|payout| successful_payouts.push payout}
        UserMailer.payday(user, completed_payouts, completed_payouts[0].job.date, completed_payouts[-1].job.date).then(:deliver) unless completed_payouts.empty?

        payouts.unprocessed.each do |payout|
          total += payout.total
        end

        if total > 0
          recipient = Stripe::Account.retrieve user.contractor_profile.stripe_recipient_id

          rsp = Stripe::Transfer.create(
            :amount => total,
            :currency => 'usd',
            :destination => recipient.id,
            :description => 'HostWise Payout',
            :statement_descriptor => 'HostWise Payout',
            :metadata => { payout_ids: payouts.unprocessed.map(&:id).to_s }
          )
          rsp = Stripe::Transfer.retrieve rsp.id

          case rsp.status
          when 'pending'
            payouts.unprocessed.each {|payout| payout.update_attributes(status_cd: 1, stripe_transfer_id: rsp.id)}
            UpdatePayoutJob.perform_later(user, payouts.map(&:id))
          when 'paid'
            payouts = payouts.unprocessed.sort_by {|payout| payout.job.date}
            payouts.each {|payout| successful_payouts.push(payout); payout.update_attributes(status_cd: 2, stripe_transfer_id: rsp.id)}
            UserMailer.payday(user, payouts, payouts[0].job.date, payouts[-1].job.date).then(:deliver)
          when 'failed'
            payouts.unprocessed.each {|payout| payout.update_attributes(status_cd: 3, stripe_transfer_id: rsp.id)}
          else
            false
          end
        end
      end
    end
    render json: { success: true, payouts: successful_payouts.map{|payout| payout.job.id}.uniq }
  end

end

require 'clockwork'

require './config/boot'
require './config/environment'

module Clockwork
  handler do |job|
    begin
      Appsignal::Transaction.create(SecureRandom.uuid, ENV.to_hash)

      ActiveSupport::Notifications.instrument(
        'perform_job.clockwork',
        :class => 'Clockwork',
        :method => 'handler'
      ) do
        case job
          when 'coupons:monitor'
            coupons = []
            Coupon.all.each do |coupon|
              coupons.push(coupon) if (coupon.limit > 0 && coupon.booking_users.any? {|user| coupon.limit < coupon.applied(user)}) || (coupon.expiration && coupon.bookings.any? {|booking| booking.date <= coupon.expiration})
            end
            body = "Coupons that might be being abused: #{coupons.map(&:id)}"
            UserMailer.generic_notification('Coupon abuse notification', body).then(:deliver)
          when 'launder:notify_and_charge'
            Property.not_purchased.each do |property|
              last_booking = property.bookings.completed.sort_by(&:date)[-1]
              if last_booking.chain(:job, :has_linens?) && last_booking.date >= Date.parse('June 2nd, 2015')
                last_transaction = last_booking.transactions.where(transaction_type_cd: 2).order(charged_at: :asc, created_at: :asc).last
                diff = (Date.today - last_booking.date).to_i
                if diff == 15
                  UserMailer.linen_recovery_notification(property).then(:deliver)
                elsif diff >= 30 && (!last_transaction || last_transaction.status_cd != 0)
                  begin
                    amount = 150 * last_booking.linen_set_count * 100
                    rsp = Stripe::Charge.create(
                      amount: amount,
                      currency: 'usd',
                      customer: property.user.stripe_customer_id,
                      source: property.user.payments.primary[0].stripe_id,
                      statement_descriptor: "HostWise Linen Recovery"[0..21], # 22 characters max
                      metadata: { property_id: property.id }
                    )
                    last_booking.transactions.create(stripe_charge_id: rsp.id, status_cd: 0, amount: amount, transaction_type_cd: 2)
                    UserMailer.linen_recovery_charge(property, amount).then(:deliver)
                  rescue Stripe::CardError => e
                    err  = e.json_body[:error]
                    property.transactions.create(stripe_charge_id: err[:charge], status_cd: 1, failure_message: err[:message], amount: amount, transaction_type_cd: 2)
                  end
                end
              end
            end
          when 'launder:notify_and_charge_reports'
            Property.not_purchased.each do |property|
              last_booking = property.bookings.sort_by(&:date)[-1]
              if last_booking.chain(:job, :has_linens?) && last_booking.date >= Date.parse('June 2nd, 2015')
                last_transaction = last_booking.transactions.where(transaction_type_cd: 2).order(charged_at: :asc, created_at: :asc).last
                diff = (Date.today - last_booking.date).to_i
                if diff == 15
                  UserMailer.linen_recovery_notification_report(property).then(:deliver)
                elsif diff >= 30 && (!last_transaction || last_transaction.status_cd != 0)
                  begin
                    amount = 150 * last_booking.linen_set_count
                    UserMailer.linen_recovery_charge_report(property, amount).then(:deliver)
                  end
                end
              end
            end
          when 'subscriptions:process'
            Property.purchased.each do |property|
              timezone = Timezone::Zone.new :zone => property.zone
              time = timezone.time Time.now
              if time.hour == 23 && (property.last_transaction.then(:status) == :failed || time.day == property.purchase_date.day && time.month == property.purchase_date.month)
                begin
                  amount = 299 * property.beds * 100
                  rsp = Stripe::Charge.create(
                    amount: amount,
                    currency: 'usd',
                    customer: property.user.stripe_customer_id,
                    source: property.user.payments.primary[0].stripe_id,
                    statement_descriptor: "HostWise"[0..21], # 22 characters max
                    metadata: { property_id: property.id }
                  )
                  property.transactions.create(stripe_charge_id: rsp.id, status_cd: 0, amount: amount, transaction_type_cd: 0)
                rescue Stripe::CardError => e
                  err  = e.json_body[:error]
                  property.transactions.create(stripe_charge_id: err[:charge], status_cd: 1, failure_message: err[:message], amount: amount, transaction_type_cd: 0)
                end
              end
            end
          when 'subscriptions:report'
            properties = []
            Property.purchased.each do |property|
              timezone = Timezone::Zone.new :zone => property.zone
              time = timezone.time Time.now
              properties.push property if time.hour == 22 && (property.last_transaction.then(:status) == :failed || time.day == property.purchase_date.day && time.month == property.purchase_date.month)
            end
            UserMailer.subscriptions_report(properties).then(:deliver) if properties.present?
          when 'payments:process'
            Booking.where(payment_status_cd: 0, status_cd: [2,3,5]).each do |booking|
              timezone = Timezone::Zone.new :zone => booking.property.zone
              time = timezone.time Time.now
              if time.hour == 22
                begin
                  booking.update_cost! if booking.status_cd == 5
                  booking.charge!
                  booking.property.update_attribute :purchase_date, time if booking.property.linen_handling_cd == 0 && !booking.property.purchase_date
                rescue
                  # report to appsignal
                end
              end
            end
          when 'jobs:notify_no_access'
            Booking.where(payment_status_cd: 0, status_cd: 5).each do |booking|
              timezone = Timezone::Zone.new :zone => booking.property.zone
              time = timezone.time Time.now
              if time.hour == 16 && time.to_date == booking.date
                TwilioJob.perform_later("+1#{booking.property.phone_number}", "HostWise was unable to access your property today. Having waited 30 minutes to resolve this issue, we had to move on to help another customer. A small charge of $#{PRICING['no_access_fee']} will be billed to your account in order to pay the housekeepers for their time.")
              end
            end
          when 'payouts:process'
            User.all.each do |user|
              if user.chain(:contractor_profile, :stripe_recipient_id)
                total = 0

                user.payouts.pending.each do |payout|
                  rsp = Stripe::Transfer.retrieve payout.stripe_transfer_id
                  case rsp.status
                  when 'paid'
                    payout.update_attribute :status_cd, 2
                  when 'failed'
                    payout.update_attribute :status_cd, 3
                  end
                end

                user.payouts.unprocessed.each do |payout|
                  total += payout.total
                end

                if total > 0
                  recipient = Stripe::Account.retrieve user.contractor_profile.stripe_recipient_id
                  user.contractor_profile.verify_stripe! if recipient.verification.fields_needed[0]

                  rsp = Stripe::Transfer.create(
                    :amount => total,
                    :currency => 'usd',
                    :destination => recipient.id,
                    :statement_descriptor => 'HostWise Payout',
                    :metadata => { payout_ids: user.payouts.unprocessed.map(&:id).to_s }
                  )

                  case rsp.status
                  when 'pending'
                    user.payouts.unprocessed.each {|payout| payout.update_attributes(status_cd: 1, stripe_transfer_id: rsp.id)}
                  when 'paid'
                    payouts = user.payouts.unprocessed.sort_by {|payout| payout.job.date}
                    payouts.each {|payout| payout.update_attributes(status_cd: 2, stripe_transfer_id: rsp.id)}
                    UserMailer.payday(user, payouts, payouts[0].job.date, payouts[-1].job.date).then(:deliver)
                  when 'failed'
                    user.payouts.unprocessed.each {|payout| payout.update_attributes(status_cd: 3, stripe_transfer_id: rsp.id)}
                  else
                    false
                  end
                end
              end
            end
          when 'payments:report'
            payments = {}
            Booking.where(payment_status_cd: 0, status_cd: [2,3,5]).each do |booking|
              timezone = Timezone::Zone.new :zone => booking.property.zone
              time = timezone.time Time.now
              if time.hour == 20
                payments[booking.user.email] ||= {amount:0,booking_ids:[]}
                payments[booking.user.email][:amount] += booking.cost
                payments[booking.user.email][:name] = booking.user.name
                payments[booking.user.email][:booking_ids].push booking.id
              end
            end
            payments.each do |email, values|
              payments[email][:booking_ids] = payments[email][:booking_ids].join ', '
            end
            UserMailer.payments_report(payments).then(:deliver) if payments.present?
          when 'payouts:report'
            payouts = {}
            User.all.each do |user|
              if user.chain(:contractor_profile, :stripe_recipient_id)
                total = 0

                user.payouts.unprocessed.each do |payout|
                  total += payout.total
                end

                if total > 0
                  payouts[user.email] = {}
                  payouts[user.email][:name] = user.name
                  payouts[user.email][:amount] = total / 100.0
                  payouts[user.email][:job_ids] = user.payouts.unprocessed.map(&:job_id).join ', '
                end
              end
            end
            UserMailer.payout_report(payouts).then(:deliver)
          when 'jobs:check_unclaimed'
            url = Rails.application.routes.url_helpers
            Job.where(status_cd: 0).each do |job|
              if job.chain(:booking, :property, :zone)
                timezone = Timezone::Zone.new :zone => job.booking.property.zone
                time = timezone.time Time.now
                if time.hour == 17 && job.tomorrow?(time.to_date)
                  UserMailer.generic_notification("Job for tomorrow not filled - #{job.id}", "Job ##{job.id} (#{job.booking.property.nickname}) for tomorrow has not been claimed by the required number of contractors - #{url.admin_job_url(job)}").then(:deliver)
                end
              end
            end
          when 'jobs:check_no_shows'
            url = Rails.application.routes.url_helpers
            zones = {}
            User.contractors.each do |contractor|
              if contractor.contractor_profile
                timezone = Timezone::Zone.new :zone => contractor.contractor_profile.zone
                time = timezone.time(Time.now-8.days)
                pickup = contractor.jobs.on_date(time).distribution.pickup[0]
                jobs_today = contractor.jobs.standard.on_date(time)
                jobs_today.each {|j| j.current_user = contractor}
                jobs_today = jobs_today.sort_by(&:priority)
                jobs_today.each do |job|
                  staging = Rails.env.staging? && '[STAGING] ' || ''
                  first_job = job == jobs_today[0]
                  last_job  = job == jobs_today[-1]
                  second_to_last = if jobs_today.count > 1 then job == jobs_today[-2] else false end

                  if job.status_cd == 1 && time.hour == job.booking.timeslot - 1
                    TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{staging}#{contractor.name} (#{contractor.id}) has not arrived at job ##{job.id} (#{job.booking.property.nickname})")
                    UserMailer.generic_notification("Contractor has not arrived - #{contractor.name}", "#{contractor.name} (#{contractor.id}) has not arrived at job ##{job.id} (#{job.booking.property.nickname}) - #{url.admin_job_url(job)}").then(:deliver)
                  end

                  if first_job && pickup.then(:not_complete?) && time.hour == job.booking.timeslot - 2
                    TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{staging}#{contractor.name} (#{contractor.id}) has not picked up linens for job ##{job.id} (#{job.booking.property.nickname})")
                    UserMailer.generic_notification("Contractor has not picked up linens - #{contractor.name}", "#{contractor.name} (#{contractor.id}) has not picked up linens for job ##{job.id} (#{job.booking.property.nickname}) - #{url.admin_job_url(job)}").then(:deliver)
                  end

                  if time.hour == 18
                    zones["#{contractor.contractor_profile.zone}"] ||= []
                    zones["#{contractor.contractor_profile.zone}"].push job
                  end

                  if time.hour == 22 && job.not_complete?
                    job.past_due!
                    job.save
                  end
                end
              end
            end
            zones.each do |zone, jobs|
              completed   = jobs.select {|job| job.status_cd > 2}.count
              in_progress = jobs.select {|job| job.status_cd == 2}.count
              not_started = jobs.select {|job| job.status_cd == 1}.count
              open        = jobs.select {|job| job.status_cd == 0}.count
              UserMailer.generic_notification("Daily Progress Report (#{zone})", "#{completed} jobs completed, #{in_progress} jobs in progress, #{not_started} jobs not started, #{open} open jobs").then(:deliver)
            end
          when 'jobs:check_timers'
            Job.where(status_cd: 5).each do |job|
              if job.booking.status != :couldnt_access && job.cant_access < Time.now.utc - 30.minutes
                job.booking.update_attribute :status_cd, 5
                job.pay_contractors!
                staging = Rails.env.staging? && '[STAGING] ' || ''
                TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{staging}#{job.primary_contractor.name} was unable to access property ##{job.booking.property.id} and the 30m timer has passed. They are now either leaving the property or have forgotten to notify us they've gotten in. This is for job ##{job.id}.")
              end
            end
          when 'bookings:nil_check'
            bookings = Booking.on_date(Date.today).select {|booking| booking.duplicate?}
            body = "Duplicate booking alert! These bookings may be duplicates: #{bookings.map(&:id).join ', '}"
            UserMailer.generic_notification("Duplicate booking alert", body).then(:deliver) if bookings.present?
          when 'linens:check_counts'
            mismatched = []
            jobs = Job.standard.complete.on_date(Date.yesterday)
            jobs.each do |job|
              king_sheets  = job.checklist.checklist_settings[:inventory_count]['king_sheets']
              twin_sheets  = job.checklist.checklist_settings[:inventory_count]['twin_sheets']
              total_sheets = king_sheets + twin_sheets
              mismatched.push job if job.soiled_pickup_count != total_sheets
            end
            body = "These jobs have potential linens that were not picked up: #{mismatched.map(&:id).join ', '}"
            UserMailer.generic_notification('Linen pickup mismatch', body).then(:deliver) if mismatched.present?
          end
      end
    rescue Exception => exception
      Appsignal::Transaction.current.add_exception(exception)
      raise exception
    ensure
      Appsignal::Transaction.current.complete!
    end
  end

  every(1.day,  'launder:notify_and_charge', at: '05:00')
  every(1.day,  'launder:notify_and_charge_reports', at: '04:00')
  every(1.hour, 'subscriptions:process', at: '**:00')
  every(1.hour, 'subscriptions:report', at: '**:30')
  every(1.hour, 'payments:process', at: '**:00')
  every(1.hour, 'payments:report', at: '**:00')
  every(1.week, 'payouts:process', at: 'Wednesday 05:00')
  every(1.week, 'payouts:report', at: 'Wednesday 03:00')
  every(1.hour, 'jobs:notify_no_access', at: '**:00')
  every(1.hour, 'jobs:check_unclaimed', at: '**:00')
  every(1.hour, 'jobs:check_no_shows', at: '**:06')
  every(1.day,  'coupons:monitor', at: '22:00')
  every(1.day,  'linens:check_counts', at: '17:00')
  every(1.day,  'bookings:nil_check', at: '17:00')
  every(10.minutes, 'jobs:check_timers')
end

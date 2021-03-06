class UserMailer < MandrillMailer::TemplateMailer
  include ActionView::Helpers::NumberHelper

  default from: 'support@hostwise.com'
  default from_name: 'HostWise'

  DEFAULT_REPLY_TO = 'HostWise <support@hostwise.com>'

  def daily_digest
    mandrill do
      mandrill_mail template: 'daily-digest',
                    to: {email: Rails.application.config.hq_notification_email},
                    vars: {
                      grand_totals: {
                        users: User.hosts.count,
                        properties: Property.count,
                        jobs: Booking.where('status_cd > 0').count
                      },
                      active_totals: {
                        users: User.hosts.active.count,
                        properties: Property.has_upcoming.count,
                        jobs: Booking.where('status_cd > 0').within_date(Date.today - 2.weeks, Date.today).count
                      },
                      daily_totals: {
                        users: User.hosts.where('users.created_at = ?', Date.yesterday).count,
                        properties: Property.where('properties.created_at = ?', Date.yesterday).count,
                        jobs: Booking.where('bookings.created_at = ?', Date.yesterday).count
                      },
                      markets: [
                        {
                          market: 'Los Angeles',
                          grand_totals: {
                            users: User.hosts.within_market(Market.find_by_name('Los Angeles')).count,
                            properties: Property.within_market(Market.find_by_name('Los Angeles')).count,
                            jobs: Booking.where('status_cd > 0').within_market(Market.find_by_name('Los Angeles')).count
                          },
                          active_totals: {
                            users: User.hosts.active.within_market(Market.find_by_name('Los Angeles')).count,
                            properties: Property.has_upcoming.within_market(Market.find_by_name('Los Angeles')).count,
                            jobs: Booking.where('status_cd > 0').within_date(Date.today - 2.weeks, Date.today).within_market(Market.find_by_name('Los Angeles')).count
                          },
                          daily_totals: {
                            users: User.hosts.where('users.created_at = ?', Date.yesterday).within_market(Market.find_by_name('Los Angeles')).count,
                            properties: Property.where('properties.created_at = ?', Date.yesterday).within_market(Market.find_by_name('Los Angeles')).count,
                            jobs: Booking.where('bookings.created_at = ?', Date.yesterday).within_market(Market.find_by_name('Los Angeles')).count
                          }
                        },
                        {
                          market: 'San Diego',
                          grand_totals: {
                            users: User.hosts.within_market(Market.find_by_name('San Diego')).count,
                            properties: Property.within_market(Market.find_by_name('San Diego')).count,
                            jobs: Booking.where('status_cd > 0').within_market(Market.find_by_name('San Diego')).count
                          },
                          active_totals: {
                            users: User.hosts.active.within_market(Market.find_by_name('San Diego')).count,
                            properties: Property.has_upcoming.within_market(Market.find_by_name('San Diego')).count,
                            jobs: Booking.where('status_cd > 0').within_date(Date.today - 2.weeks, Date.today).within_market(Market.find_by_name('San Diego')).count
                          },
                          daily_totals: {
                            users: User.hosts.where('users.created_at = ?', Date.yesterday).within_market(Market.find_by_name('San Diego')).count,
                            properties: Property.where('properties.created_at = ?', Date.yesterday).within_market(Market.find_by_name('San Diego')).count,
                            jobs: Booking.where('bookings.created_at = ?', Date.yesterday).within_market(Market.find_by_name('San Diego')).count
                          }
                        }
                      ]
                    },
                    merge_language: 'handlebars',
                    inline_css: true,
                    async: true
    end
  end

  def report(subject, body, email)
    mandrill_mail template: 'generic-notification',
                  subject: subject,
                  to: {email: email},
                  vars: {
                    'BODY' => body
                  },
                  inline_css: true,
                  async: true
  end

  def generic_notification(subject, body)
    mandrill do
      mandrill_mail template: 'generic-notification',
                    subject: subject,
                    to: {email: Rails.application.config.support_notification_email},
                    vars: {
                      'BODY' => body
                    },
                    inline_css: true,
                    async: true
    end
  end

  def background_check_notification(subject, body)
    mandrill do
      mandrill_mail template: 'generic-notification',
                    subject: subject,
                    to: {email: Rails.application.config.jobs_notification_email},
                    vars: {
                      'BODY' => body
                    },
                    inline_css: true,
                    async: true
    end
  end

  def cancelled_booking_notification booking
    mandrill do
      mandrill_mail template: 'cancelled-booking-notification',
                    subject: "[Hosts] Delete Appointment #{booking.date.strftime}",
                    to: {email: Rails.application.config.booking_notification_email},
                    vars: {
                      'ID' => booking.id,
                      'CUST_NAME' => booking.property.user.name,
                      'CUST_PHONE' => booking.property.user.display_phone_number,
                      'CUST_EMAIL' => booking.property.user.email,
                      'FULL_ADDRESS' => booking.property.full_address,
                      'SERVICE_DATE' => booking.date.strftime,
                      'NICKNAME' => booking.property.nickname,
                      'SERVICES' => booking.services.map(&:display).join(', '),
                      'ACCESS' => booking.property.access_info,
                      'PARKING' => booking.property.parking_info,
                      'TRASH' => booking.property.trash_disposal,
                      'RESTOCKING' => booking.property.restocking_info,
                      'SPECIAL_INSTRUCTIONS' => booking.property.additional_info,
                      'PROP_SIZE' => booking.property.property_size,
                      'KING' => booking.property.king_beds,
                      'QUEEN' => booking.property.queen_beds,
                      'FULL' => booking.property.full_beds,
                      'TWIN' => booking.property.twin_beds
                    },
                    inline_css: true,
                    async: true
    end
  end

  def new_booking_notification booking
    mandrill do
      mandrill_mail template: 'new-booking-notification',
                    subject: "Turn Needed on #{booking.date.strftime}",
                    to: {email: Rails.application.config.booking_notification_email},
                    vars: {
                      'ID' => booking.id,
                      'CUST_NAME' => booking.property.user.name,
                      'CUST_PHONE' => booking.property.user.display_phone_number,
                      'CUST_EMAIL' => booking.property.user.email,
                      'FULL_ADDRESS' => booking.property.full_address,
                      'SERVICE_DATE' => booking.date.strftime,
                      'NICKNAME' => booking.property.nickname,
                      'SERVICES' => booking.services.map(&:display).join(', '),
                      'ACCESS' => booking.property.access_info,
                      'PARKING' => booking.property.parking_info,
                      'TRASH' => booking.property.trash_disposal,
                      'RESTOCKING' => booking.property.restocking_info,
                      'SPECIAL_INSTRUCTIONS' => booking.property.additional_info,
                      'PROP_SIZE' => booking.property.property_size,
                      'KING' => booking.property.king_beds,
                      'QUEEN' => booking.property.queen_beds,
                      'FULL' => booking.property.full_beds,
                      'TWIN' => booking.property.twin_beds
                    },
                    inline_css: true,
                    async: true
    end
  end

  def contact_email(subject, email, message, first_name, last_name, phone_number)
    mandrill do
      mandrill_mail template: 'contact-email',
                    subject: subject,
                    to: {email: Rails.application.config.support_notification_email},
                    vars: {
                      'MESSAGE' => message,
                      'NAME' => "#{first_name} #{last_name}",
                      'NUMBER' => phone_number
                    },
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => "#{first_name} #{last_name} <#{email}>"}
    end
  end

  def reset_password_email(user, url)
    mandrill do
      mandrill_mail template: 'reset-password',
                    subject: 'Your password has been reset',
                    to: {email: user.email},
                    vars: {'RESET_LINK' => url},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def welcome(user)
    mandrill do
      mandrill_mail template: 'welcome',
                    subject: 'Welcome to HostWise!',
                    to: {email: user.email, name: user.name},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def booking_reminder(booking, user)
    mandrill do
      date = booking.date.strftime('%A, %b %e')
      unless user.deactivated?
        mandrill_mail template: 'service-reminder',
                      subject: "Reminder: Service Tomorrow #{date}",
                      to: {email: user.email, name: user.name},
                      vars: {
                        'PROP_LINK' => property_url(booking.property.slug),
                        'DATE' => date,
                        'ADDRESS' => booking.property.full_address,
                        'SERVICES' => booking.services.map(&:display).join(', '),
                        'PROP_SIZE' => booking.property.property_size,
                        'START_HOUR' => booking.arrival_start_hour,
                        'END_HOUR' => booking.arrival_end_hour,
                        'COMPLETE_HOUR' => booking.display_complete_hour
                      },
                      inline_css: true,
                      async: true,
                      headers: {'Reply-To' => DEFAULT_REPLY_TO}
      end
    end
  end

  def announcement(user, template)
    mandrill do
      mandrill_mail template: template,
                    to: {email: user.email, name: user.name},
                    vars: {},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def booking_confirmation(booking)
    mandrill do
      date = booking.date.strftime('%b %e, %Y')
      unless booking.property.user.deactivated?
        mandrill_mail template: 'booking-confirmation',
                      subject: "Booking confirmed on #{date} for #{booking.property.nickname}",
                      to: {email: booking.property.user.email, name: booking.property.user.name},
                      vars: {'NICKNAME' => booking.property.nickname,
                             'PROP_SIZE' => booking.property.property_size,
                             'SERVICES' => booking.services.map(&:display).join(', '),
                             'PRICE' => "$#{booking.cost}",
                             'ADDRESS' => booking.property.full_address,
                             'PROP_LINK' => property_url(booking.property.slug),
                             'DATE' => date},
                      inline_css: true,
                      async: true,
                      headers: {'Reply-To' => DEFAULT_REPLY_TO}
      end
    end
  end

  def property_confirmation(property)
    mandrill do
      mandrill_mail template: 'property-added',
                    subject: "Property Added Successfully. What's Next?",
                    to: {email: property.user.email, name: property.user.name},
                    vars: {
                      'ADDRESS' => property.full_address,
                      'NICKNAME' => property.nickname,
                      'PROP_SIZE' => property.property_size,
                      'PROP_LINK' => property_url(property.slug)
                    },
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def service_completed booking
    mandrill do
      date = booking.date.strftime('%b %e, %Y')
      payment_method = booking.payment.stripe_id.present? ? booking.payment.card_type : booking.payment.bank_name
      unless booking.property.user.deactivated?
        mandrill_mail template: 'service-completed',
                      subject: 'Thank you for using HostWise',
                      to: {email: booking.property.user.email, name: booking.property.user.name},
                      vars: {
                        date: date,
                        nickname: booking.property.nickname,
                        address: booking.property.full_address,
                        payment_method: payment_method.upcase,
                        account_num: booking.payment.last4,
                        price: "$#{booking.cost}",
                        contractor_service: booking.contractor_service_cost > 0,
                        contractor_service_cost: booking.contractor_service_cost,
                        linens: booking.linens_cost > 0,
                        linens_cost: booking.linens_cost,
                        toiletries: booking.toiletries_cost > 0,
                        toiletries_cost: booking.toiletries_cost,
                        late_same_day: booking.late_same_day,
                        late_next_day: booking.late_next_day,
                        first_booking_discount: booking.first_booking_discount,
                        first_booking_discount_amount: booking.first_booking_discount_cost,
                        discounted: booking.discounted,
                        discounted_cost: booking.discounted_cost / 100.0,
                        discounted_reason: booking.discounted_reason,
                        overage: booking.overage,
                        overage_cost: booking.overage_cost / 100.0,
                        overage_reason: booking.overage_reason,
                        extra_king_sets: booking.extra_king_sets > 0,
                        extra_king_sets_cost: booking.extra_king_sets_cost,
                        extra_twin_sets: booking.extra_twin_sets > 0,
                        extra_twin_sets_cost: booking.extra_twin_sets_cost,
                        extra_toiletry_sets: booking.extra_toiletry_sets > 0,
                        extra_toiletry_sets_cost: booking.extra_toiletry_sets_cost,
                        coupon: booking.coupon_cost > 0,
                        coupon_cost: booking.coupon_cost / 100.0,
                        prop_link: property_url(booking.property.slug)
                      },
                      merge_language: 'handlebars',
                      inline_css: true,
                      async: true,
                      headers: {'Reply-To' => DEFAULT_REPLY_TO}
      end
    end
  end

  def contractor_welcome_email(user, url)
    mandrill do
      mandrill_mail template: 'contractor-welcome',
                    subject: 'Thank you for joining our community!',
                    to: {email: user.email, name: user.name},
                    vars: {'APPLICATION_LINK' => url},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def contractor_hired_email(user)
    mandrill do
      mandrill_mail template: 'hired',
                    to: {email: user.email, name: user.name},
                    vars: {
                      'CALL_ACTION_URL' => contractor_jobs_url,
                      'CONTRACTOR_FNAME' => user.first_name
                    },
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def mentor_promotion_email(user)
    mandrill do
      mandrill_mail template: 'promoted-mentor',
                    to: {email: user.email, name: user.name},
                    vars: {
                      'CALL_ACTION_URL' => contractor_jobs_url,
                      'CONTRACTOR_FNAME' => user.first_name
                    },
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def launch_email(user, url)
    mandrill do
      mandrill_mail template: 'launch-announcement',
                    subject: "It's official! Porter is now HostWise.",
                    to: {email: user.email},
                    vars: {'RESET_LINK' => url},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def booking_cancellation(booking)
    mandrill do
      date = booking.date.strftime('%A, %b %e')
      unless booking.property.user.deactivated?
        mandrill_mail template: 'cancellation',
                      subject: "Booking cancelled on #{date} at #{booking.property.nickname}",
                      to: {email: booking.property.user.email, name: booking.property.user.name},
                      vars: {'ADDRESS' => booking.property.full_address,
                             'NICKNAME' => booking.property.nickname,
                             'DATE' => date},
                      inline_css: true,
                      async: true,
                      headers: {'Reply-To' => DEFAULT_REPLY_TO}
      end
    end
  end

  def booking_same_day_cancellation(booking)
    mandrill do
      date = booking.date.strftime('%A, %b %e')
      payment_method = booking.payment.stripe_id.present? ? booking.payment.card_type : booking.payment.bank_name
      unless booking.property.user.deactivated?
        mandrill_mail template: 'cancellation-same-day',
                      subject: "Booking cancelled on #{date} at #{booking.property.nickname}",
                      to: {email: booking.property.user.email, name: booking.property.user.name},
                      vars: {'ADDRESS' => booking.property.full_address,
                             'NICKNAME' => booking.property.nickname,
                             'PAYMENT_METHOD' => payment_method.upcase,
                             'ACCOUNT_NUM' => booking.payment.last4,
                             'CANCEL_FEE' => "$#{booking.cost}",
                             'DATE' => date},
                      inline_css: true,
                      async: true,
                      headers: {'Reply-To' => DEFAULT_REPLY_TO}
      end
    end
  end

  def contractor_profile_completed(user)
    mandrill do
      unless user.deactivated?
        mandrill_mail template: 'profile-completed',
                      to: {email: user.email, name: user.name},
                      vars: {},
                      inline_css: true,
                      async: true,
                      headers: {'Reply-To' => DEFAULT_REPLY_TO}
      end
    end
  end

  def new_open_job(user, job)
    mandrill do
      unless user.deactivated?
        mandrill_mail template: 'new-open-job',
                      to: {email: user.email, name: user.name},
                      vars: {
                        'CONTRACTOR_NAME' => user.name,
                        'SERVICE_DATE' => job.booking.date.strftime,
                        'SHORT_ADDRESS' => job.booking.property.neighborhood,
                        'CLAIM_LINK' => contractor_jobs_url
                      },
                      inline_css: true,
                      async: true,
                      headers: {'Reply-To' => DEFAULT_REPLY_TO}
      end
    end
  end

  def new_jobs(user)
    mandrill do
      unless user.deactivated?
        mandrill_mail template: 'new-jobs',
                      subject: 'New HostWise Jobs!',
                      to: {email: user.email, name: user.name},
                      vars: {
                        'CONTRACTOR_NAME' => user.name,
                        'CLAIM_LINK' => contractor_jobs_url
                      },
                      inline_css: true,
                      async: true,
                      headers: {'Reply-To' => DEFAULT_REPLY_TO}
      end
    end
  end

  def job_claim_confirmation(job, user)
    mandrill do
      unless user.deactivated?
        mandrill_mail template: 'job-claim-confirmation',
                      to: {email: user.email, name: user.name},
                      vars: {
                        'CONTRACTOR_NAME' => user.name,
                        'SERVICE_DATE' => job.booking.date.strftime,
                        'FULL_ADDRESS' => job.booking.property.full_address,
                        'PROP_SIZE' => job.booking.property.property_size,
                        'SERVICES' => job.booking.services.map(&:display).join(', '),
                        'KING' => job.booking.property.king_beds,
                        'QUEEN' => job.booking.property.queen_beds,
                        'FULL' => job.booking.property.full_beds,
                        'TWIN' => job.booking.property.twin_beds,
                        'DETAILS_LINK' => job_details_url(job.id)
                      },
                      inline_css: true,
                      async: true,
                      headers: {'Reply-To' => DEFAULT_REPLY_TO}
      end
    end
  end

  def background_check_verified(user)
    mandrill do
      mandrill_mail template: 'background-verified',
                    to: {email: user.email, name: user.name},
                    vars: {
                      'DASHBOARD_LINK' => contractor_schedule_url
                    },
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def background_check_failed(user)
    mandrill do
      mandrill_mail template: 'background-check-failed',
                    to: {email: user.email, name: user.name},
                    vars: {},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def payday(user, payouts, from, to)
    mandrill do
      mandrill_mail template: 'payday',
                    to: {email: user.email, name: user.name},
                    subject: "HostWise Payday! (#{from.strftime('%m/%d')} - #{to.strftime('%m/%d')})",
                    vars: {
                      action_url: contractor_jobs_url,
                      total: payouts.reduce(0) {|acc, payout| acc + payout.total} / 100.0,
                      bank: user.payments[0].last4,
                      from_date: from.strftime('%b %-d, %Y'),
                      to_date: to.strftime('%b %-d, %Y'),
                      jobs: payouts.map {|payout| {
                        id: payout.job.id,
                        link: job_details_url(payout.job),
                        formatted_date: payout.job.date.strftime,
                        payout: payout.total / 100.0,
                        payout_addition: payout.addition,
                        payout_subtraction: payout.subtraction,
                        payout_additional_amount: payout.additional_amount,
                        payout_subtracted_amount: payout.subtracted_amount,
                        payout_additional_reason: payout.additional_reason,
                        payout_subtracted_reason: payout.subtracted_reason,
                        services: payout.job.booking.services.map(&:display).join(', ')
                      }}
                    },
                    merge_language: 'handlebars',
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def subscriptions_report properties
    mandrill do
      mandrill_mail template: 'subscriptions-breakdown',
                    to: Rails.application.config.support_notification_email,
                    subject: "HostWise Linen Subscriptions Breakdown",
                    vars: {
                      properties: properties.map {|property| {
                        name: property.nickname,
                        property_id: property.id,
                        amount: number_with_precision(299 * property.beds, precision: 2, delimiter: ',')
                      }}
                    },
                    merge_language: 'handlebars',
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def payments_report payments
    mandrill do
      mandrill_mail template: 'payments-breakdown',
                    to: Rails.application.config.support_notification_email,
                    subject: "HostWise Payments Breakdown",
                    vars: {
                      payments: payments.map {|email, payment| {
                        name: payment[:name],
                        booking_ids: payment[:booking_ids],
                        amount: payment[:amount]
                      }}
                    },
                    merge_language: 'handlebars',
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def payout_report payouts
    mandrill do
      mandrill_mail template: 'payout-breakdown',
                    to: Rails.application.config.support_notification_email,
                    subject: "HostWise Payout Breakdown",
                    vars: {
                      payouts: payouts.map {|email, payout| {
                        name: payout[:name],
                        amount: payout[:amount],
                        job_ids: payout[:job_ids]
                      }}
                    },
                    merge_language: 'handlebars',
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def linen_recovery_notification property
    mandrill do
      mandrill_mail template: 'linen-recovery-program-15-days',
                    to: {email: property.user.email, name: property.user.name},
                    vars: {
                      'NICKNAME' => property.nickname
                    },
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def linen_recovery_charge property, amount
    mandrill do
      mandrill_mail template: 'linen-recovery-charged',
                    to: {email: property.user.email, name: property.user.name},
                    vars: {
                      'NICKNAME' => property.nickname,
                      'AMOUNT'   => amount / 100.0
                    },
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def linen_recovery_notification_report property
    mandrill do
      mandrill_mail template: 'linen-recovery-program-15-days-report',
                    to: Rails.application.config.support_notification_email,
                    vars: {
                      'NICKNAME' => property.nickname,
                      'ID'       => property.id
                    },
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def linen_recovery_charge_report property, amount
    mandrill do
      mandrill_mail template: 'linen-recovery-charged-report',
                    to: Rails.application.config.support_notification_email,
                    vars: {
                      'NICKNAME' => property.nickname,
                      'AMOUNT'   => amount,
                      'NAME'     => property.user.name,
                      'ID'       => property.user.id
                    },
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def linen_feedback user
    mandrill do
      mandrill_mail template: 'linen-options-ui-feedback',
                    to: user.email,
                    vars: { 'NAME' => user.first_name },
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  private

  def mandrill
    yield if Rails.env.production? || Rails.env.staging?
  end
end

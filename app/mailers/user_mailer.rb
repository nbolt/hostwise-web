class UserMailer < MandrillMailer::TemplateMailer

  default from: 'support@hostwise.com'
  default from_name: 'HostWise'

  DEFAULT_REPLY_TO = 'HostWise <support@hostwise.com>'

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
                        'PROP_SIZE' => booking.property.property_size
                      },
                      inline_css: true,
                      async: true,
                      headers: {'Reply-To' => DEFAULT_REPLY_TO}
      end
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

  def service_completed(booking)
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
                        services: booking.services.map {|service| {
                          display: service.display,
                          cost: Booking.cost(booking.property, booking.services, booking.first_booking_discount, booking.late_next_day, booking.late_same_day, booking.no_access_fee)[service.name.to_sym]
                        }},
                        price: "$#{booking.cost}",
                        late_same_day: booking.late_same_day,
                        late_next_day: booking.late_next_day,
                        first_booking_discount: booking.first_booking_discount,
                        first_booking_discount_amount: Booking.cost(booking.property, booking.services, booking.first_booking_discount, booking.late_next_day, booking.late_same_day, booking.no_access_fee)[:first_booking_discount],
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
                      total: payouts.reduce(0) {|acc, payout| acc + payout.amount} / 100.0,
                      bank: user.payments[0].last4,
                      from_date: from.strftime('%b %-d, %Y'),
                      to_date: to.strftime('%b %-d, %Y'),
                      jobs: payouts.map {|payout| {
                        id: payout.job.id,
                        link: job_details_url(payout.job),
                        formatted_date: payout.job.date.strftime,
                        payout: payout.amount / 100.0,
                        services: payout.job.booking.services.map(&:display).join(', ')
                      }}
                    },
                    merge_language: 'handlebars',
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def payday_report(user, payouts, from, to)
    mandrill do
      mandrill_mail template: 'payday',
                    to: 'staging-notifications@hostwise.com',
                    subject: "HostWise Payday Report (#{user.name})",
                    vars: {
                      action_url: contractor_jobs_url,
                      total: payouts.reduce(0) {|acc, payout| acc + payout.amount} / 100.0,
                      bank: user.payments[0].last4,
                      from_date: from.strftime('%b %-d, %Y'),
                      to_date: to.strftime('%b %-d, %Y'),
                      jobs: payouts.map {|payout| {
                        id: payout.job.id,
                        link: job_details_url(payout.job),
                        formatted_date: payout.job.date.strftime,
                        payout: payout.amount / 100.0,
                        services: payout.job.booking.services.map(&:display).join(', ')
                      }}
                    },
                    merge_language: 'handlebars',
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

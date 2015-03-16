class UserMailer < MandrillMailer::TemplateMailer

  default from: 'support@hostwise.com'
  default from_name: 'HostWise'

  DEFAULT_REPLY_TO = 'HostWise <support@hostwise.com>'

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
                      'SERVICES' => booking.services.map(&:display).join(','),
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
                      'SERVICES' => booking.services.map(&:display).join(','),
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

  def booking_confirmation(booking)
    mandrill do
      date = booking.date.strftime('%b %e, %Y')
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
      mandrill_mail template: 'service-completed',
                    subject: 'Thank you for using HostWise',
                    to: {email: booking.property.user.email, name: booking.property.user.name},
                    vars: {
                      'DATE' => date,
                      'NICKNAME' => booking.property.nickname,
                      'ADDRESS' => booking.property.full_address,
                      'PAYMENT_METHOD' => payment_method.upcase,
                      'ACCOUNT_NUM' => booking.payment.last4,
                      'SERVICES' => booking.services.map(&:display).join(', '),
                      'PRICE' => "$#{booking.cost}",
                      'PROP_LINK' => property_url(booking.property.slug)
                    },
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
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

  def booking_same_day_cancellation(booking)
    mandrill do
      date = booking.date.strftime('%A, %b %e')
      payment_method = booking.payment.stripe_id.present? ? booking.payment.card_type : booking.payment.bank_name
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

  def new_open_job(user, job)
    mandrill do
      mandrill_mail template: 'new-open-job',
                    subject: 'New job',
                    to: {email: user.email, name: user.name},
                    vars: {},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def job_claim_confirmation(job, user)
    mandrill do
      mandrill_mail template: 'job-claim-confirmation',
                    subject: 'You claimed a job',
                    to: {email: user.email, name: user.name},
                    vars: {},
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

class UserMailer < MandrillMailer::TemplateMailer

  default from: 'support@hostwise.com'
  default from_name: 'HostWise'

  DEFAULT_REPLY_TO = 'HostWise <support@hostwise.com>'

  def contact_email(email, message, first_name, last_name, phone_number)
    mandrill do
      mandrill_mail template: 'contact-email',
                    subject: "Message from #{first_name} #{last_name}",
                    to: {email: 'support@hostwise.com'},
                    vars: {'MESSAGE' => message, 'NAME' => "#{first_name} #{last_name}", 'NUMBER' => phone_number},
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
      mandrill_mail template: 'signup-success',
                    subject: 'Thank you for joining our community!',
                    to: {email: user.email, name: user.name},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def booking_reminder(booking)
    mandrill do
      mandrill_mail template: '1-service-reminder-24h-before',
                    subject: 'Just a friendly reminder about your services tomorrow.',
                    to: {email: booking.property.user.email, name: booking.property.user.name},
                    vars: {'ADDR' => booking.property.short_address},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def booking_confirmation(booking)
    mandrill do
      appt_date = booking.date.strftime('%b %e/%Y')
      mandrill_mail template: 'service-confirmation',
                    subject: "Your services have been booked on #{appt_date} at #{booking.property.short_address}",
                    to: {email: booking.property.user.email, name: booking.property.user.name},
                    vars: {'ADDR' => booking.property.short_address,
                           'DATE' => appt_date},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def property_confirmation(property)
    mandrill do
      mandrill_mail template: 'property-confirmation',
                    subject: "You've added a new propery at #{property.short_address}",
                    to: {email: property.user.email, name: property.user.name},
                    vars: {'ADDR' => property.short_address},
                    inline_css: true,
                    async: true,
                    headers: {'Reply-To' => DEFAULT_REPLY_TO}
    end
  end

  def service_completed(property)
    mandrill do
      mandrill_mail template: '0-service-completed-payment-collected',
                    subject: "Your services have been completed at #{property.short_address}",
                    to: {email: property.user.email, name: property.user.name},
                    vars: {'ADDR' => property.short_address},
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

  private

  def mandrill
    yield if Rails.env.production?
  end
end

class Contractor::NotificationsController < Contractor::AuthController
  def update
    params[:user][:notification_settings].each do |key, value|
      value.each do |k,v|
        current_user.settings(key.to_sym).sms = v if k == 'sms'
        current_user.settings(key.to_sym).email = v if k == 'email'
      end
    end

    current_user.save
    render json: { success: true }
  end
end

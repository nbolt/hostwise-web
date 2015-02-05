class Host::ServiceNotificationsController < Host::AuthController
  def create
    notification = ServiceNotification.new({zip: params[:zip]})
    notification.user = current_user
    notification.save
    render nothing: true
  end
end

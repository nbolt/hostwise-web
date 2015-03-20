require 'json'

class NotificationsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def checkr
    if params['type'] == 'report.completed'
      status = params[:data][:object][:status]
      order_id = params[:data][:object][:id]
      BackgroundCheckNotificationJob.perform_later(order_id, status)
    end

    render nothing: true
  end

  def docusign
    user = User.find_by_id params['id']
    DocusignNotificationJob.perform_later(user)

    render nothing: true
  end
end

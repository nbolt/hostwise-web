class NotificationsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def background_check
    doc = Nokogiri::XML params[:Status]
    order_id = doc.xpath('//OrderId').text
    order_status = doc.xpath('//ScreeningStatus//OrderStatus').text.split(':').last
    BackgroundCheckNotificationJob.perform_later(order_id, order_status)

    render nothing: true
  end
end

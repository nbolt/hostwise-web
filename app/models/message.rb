class Message < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper

  belongs_to :user

  before_save :remove_html_tags

  validates_presence_of :body
  validates_length_of :body, maximum: 3000, if: lambda { body.present? }

  private

  def remove_html_tags
    self.body = strip_tags self.body
  end
end

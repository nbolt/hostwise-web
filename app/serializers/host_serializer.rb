class HostSerializer < ActiveModel::Serializer
  attributes :id, :name, :display_phone_number, :avatar, :property_count, :next_service_date, :total_spent, :status, :email, :created_at

  has_many :comments, serializer: HostCommentSerializer
end

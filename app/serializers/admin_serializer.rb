class AdminSerializer
  include JSONAPI::Serializer
  
  attributes :id, :email, :created_at
end
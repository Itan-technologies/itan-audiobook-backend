class AuthorSerializer
  include JSONAPI::Serializer

  attributes :id, :email, :created_at, :first_name, :last_name, 
             :bio, :phone_number, :country, :location
end

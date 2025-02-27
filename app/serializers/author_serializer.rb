class AuthorSerializer
  include JSONAPI::Serializer

  attributes :id, :email, :created_at
end

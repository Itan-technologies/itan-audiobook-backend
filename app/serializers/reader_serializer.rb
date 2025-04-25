class ReaderSerializer
  include JSONAPI::Serializer
  attributes :email, :first_name, :last_name, :created_at, :updated_at
end
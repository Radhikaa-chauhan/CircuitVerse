FactoryBot.define do
  factory :lti_platform do
    issuer { "MyString" }
    client_id { "MyString" }
    auth_endpoint { "MyString" }
    token_endpoint { "MyString" }
    jwks_url { "MyString" }
    deployment_id { "MyString" }
  end
end

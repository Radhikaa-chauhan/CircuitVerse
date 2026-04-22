class Avo::Resources::LtiPlatform < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :issuer, as: :text
    field :client_id, as: :text
    field :auth_endpoint, as: :text
    field :token_endpoint, as: :text
    field :jwks_url, as: :text
    field :deployment_id, as: :text
  end
end

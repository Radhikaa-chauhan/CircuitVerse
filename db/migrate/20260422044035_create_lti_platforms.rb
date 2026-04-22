class CreateLtiPlatforms < ActiveRecord::Migration[8.0]
  def change
    create_table :lti_platforms do |t|
      t.string :issuer
      t.string :client_id
      t.string :auth_endpoint
      t.string :token_endpoint
      t.string :jwks_url
      t.string :deployment_id

      t.timestamps
    end
  end
end

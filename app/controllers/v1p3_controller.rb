class V1p3Controller < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!, raise: false
  protect_from_forgery with: :null_session

  def jwks
    key_path    = Rails.root.join('config', 'lti_private_key.pem')
    private_key = OpenSSL::PKey::RSA.new(File.read(key_path))
    public_key  = private_key.public_key
    jwk = JSON::JWK.new(public_key, kid: 'circuitverse-lti-key-1')
    render json: { keys: [jwk] }
  end

  def oidc_login
    platform = LtiPlatform.find_by!(
      issuer:    params[:iss],
      client_id: params[:client_id]
    )

    state = SecureRandom.hex(16)
    nonce = SecureRandom.hex(16)

    # Store in Rails cache instead of session
    Rails.cache.write("lti_state_#{state}", nonce, expires_in: 5.minutes)

    redirect_params = {
      scope:            'openid',
      response_type:    'id_token',
      response_mode:    'form_post',
      prompt:           'none',
      client_id:        params[:client_id],
      redirect_uri:     lti_v1p3_callback_url,
      login_hint:       params[:login_hint],
      lti_message_hint: params[:lti_message_hint],
      state:            state,
      nonce:            nonce
    }

    redirect_to "#{platform.auth_endpoint}?#{redirect_params.to_query}",
                allow_other_host: true
  end

  def oidc_callback
    state = params[:state]
    # Retrieve nonce from cache using state as key
    nonce = Rails.cache.read("lti_state_#{state}")

    if nonce.nil?
      render plain: "Invalid or expired state", status: :unauthorized and return
    end

    # Delete it so it can't be reused
    Rails.cache.delete("lti_state_#{state}")

    unverified = JSON::JWT.decode(params[:id_token], :skip_verification)
    platform   = LtiPlatform.find_by!(issuer: unverified[:iss])

    jwks_response = Net::HTTP.get(URI(platform.jwks_url))
    jwks          = JSON::JWK::Set.new(JSON.parse(jwks_response))
    id_token      = JSON::JWT.decode(params[:id_token], jwks)

    unless id_token[:nonce] == nonce
      render plain: "Invalid nonce", status: :unauthorized and return
    end

    session[:is_lti]      = true
    session[:lti_version] = '1.3'
    session[:lti_claims]  = id_token.to_h

    render plain: "LTI 1.3 Launch successful! User: #{id_token[:email] || id_token[:sub]}"
  end
end
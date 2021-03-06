require 'base64'
require 'cgi'
require 'openssl'
require 'hmac-sha1'
module QuickBlox
  class UserAuthorizedSession

    attr_accessor :_id
    attr_accessor :application_id
    attr_accessor :created_at
    attr_accessor :device_id
    attr_accessor :nonce
    attr_accessor :token
    attr_accessor :ts
    attr_accessor :updated_at
    attr_accessor :user_id
    attr_accessor :id

    def initialize(login, password)

      raise QuickBlox::Exceptions::MissingConfiguration unless QuickBlox.configuration

      timestamp = Time.now.in_time_zone('UTC').to_i
      nonce = timestamp - 425346
      signature = HMAC::SHA1.hexdigest(QuickBlox.configuration.auth_secret, "application_id=#{ QuickBlox.configuration.application_id }&auth_key=#{ QuickBlox.configuration.auth_key }&nonce=#{ nonce }&timestamp=#{ timestamp }&user[login]=#{ login }&user[password]=#{ password }")

      RestClient::Request.execute(
          method: :post,
          url: "#{ QuickBlox.configuration.host }/session.json",
          payload: {
              application_id: QuickBlox.configuration.application_id,
              auth_key: QuickBlox.configuration.auth_key,
              signature: signature,
              timestamp: timestamp,
              nonce: nonce,
              user: {
                  login: login,
                  password: password
              }
          }.to_json,
          headers: {
              'Content-Type': 'application/json',
              'QuickBlox-REST-API-Version': QuickBlox.configuration.api_version,
          }
      ){ |response, request, result|
        response = JSON.parse(response)

        case result.code.to_i
          when 200, 201, 202
            response['session'].each do |k, v|
              self.instance_variable_set "@#{k}", v
            end
          else
            raise QuickBlox::Exceptions::Response, response['errors']
        end
      }
    end

  end
end
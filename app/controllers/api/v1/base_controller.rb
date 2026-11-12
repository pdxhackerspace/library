module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_api_key!

      attr_reader :current_api_key

      private

      def authenticate_api_key!
        @current_api_key = authenticate_with_http_token { |token, _options| ApiKey.authenticate(token) }
        return @current_api_key.record_use! if @current_api_key

        request_http_token_authentication
      end

      def request_http_token_authentication(realm = 'Library API', _message = nil)
        headers['WWW-Authenticate'] = %(Bearer realm="#{realm}")
        render json: { error: 'A valid API key is required.' }, status: :unauthorized
      end
    end
  end
end

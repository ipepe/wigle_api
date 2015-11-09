# encoding: utf-8

module WigleApi
  class Connection
    def self.new(*args)
      @@instance ||= super
    end

    def initialize
      @connection = Net::HTTP.new(WIGLE_URI.host, WIGLE_URI.port)
      @connection.ca_file = "/etc/pki/tls/certs/ca-bundle.crt"
      @connection.use_ssl = true
      # @connection.verify_mode = OpenSSL::SSL::VERIFY_PEER
      @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE

      @logged_in = false
    end

    def login(username, password)
      return true if @logged_in

      login_form_data = {
        "credential_0" => username,
        "credential_1" => password,
        "destination" => "/gps/gps/main",
        "noexpire" => "on",
      }

      response = post(WIGLE_LOGIN_URL, login_form_data)

      if response["Set-Cookie"].nil?
        return false
      end
      
      @auth_cookie = response["Set-Cookie"]
      @logged_in = true
    end

    def search(data)
      raise NotLoggedIn unless @logged_in

      response = post(WIGLE_QUERY_URL, data)
    end

    private

    def post(path, data)
      request = Net::HTTP::Post.new(path)
      request.initialize_http_header({
        "User-Agent" => "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:42.0) Gecko/20100101 Firefox/42.0"
      })
      request.set_form_data(data)
      request.add_field("Cookie", @auth_cookie) if @auth_cookie

      @connection.start do |http|
        http.request(request)
      end
    end
  end
end


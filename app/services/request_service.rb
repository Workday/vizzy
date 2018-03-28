
# Helper class to encapsulate common request methods and authentication
class RequestService
  def initialize(server_url, user=nil, pass=nil)
    uri = URI(server_url)
    @http = Net::HTTP.new(uri.host, uri.port)
    if server_url.start_with?("https")
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end

    @user = user
    @pass = pass
  end

  def make_request(req)
    unless @user.blank? and @pass.blank?
      req.basic_auth(@user, @pass)
    end
    begin
      response = @http.request(req)
      puts "Response HTTP Status Code: #{response.code}"
      puts "Response HTTP Response Body: #{response.body}"
      handle_response(response)
    rescue StandardError => e
      Bugsnag.notify(e)
      puts "HTTP Request failed (#{e.message})"
    end
  end

  def handle_response(response)
    case response
      when Net::HTTPSuccess
        if response.body.blank?
          {success: "Empty Response Body"}
        elsif response.body == 'ok'
          {success: "Ok"}
        else
          JSON.parse(response.body)
        end
      when Net::HTTPUnauthorized
        {error: "Unauthorized: #{response.message}"}
      when Net::HTTPServerError
        {error: "Server Error: #{response.message}"}
      else
        if response.message.blank?
          {error: response.body}
        else
          {error: response.message}
        end
    end
  end
end
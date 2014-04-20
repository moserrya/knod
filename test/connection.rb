require 'net/http'
require 'json'

class Connection

  def initialize(endpoint)
    uri = URI.parse(endpoint)
    @http = Net::HTTP.new(uri.host, uri.port)
  end

  VERB_MAP = {
    get:    Net::HTTP::Get,
    post:   Net::HTTP::Post,
    put:    Net::HTTP::Put,
    patch:  Net::HTTP::Patch,
    delete: Net::HTTP::Delete,
    head:   Net::HTTP::Head,
    options: Net::HTTP::Options
  }

  VERB_MAP.keys.each do |method|
    define_method method, ->(path, params=nil) {request_json method, path, params}
  end

  private

  def request_json(method, path, params)
    response = request(method, path, params)
    response.body = JSON.parse(response.body, symbolize_names: true)
    response
  rescue
    response
  end

  def request(method, path, params = {})
    case method
    when :get, :head
      full_path = encode_path_params(path, params)
      request = VERB_MAP[method.to_sym].new(full_path)
    else
      request = VERB_MAP[method.to_sym].new(path)
      request.body = params.to_json
    end

    @http.request(request)
  end

  def encode_path_params(path, params)
    return path if params.nil?
    encoded = URI.encode_www_form(params)
    [path, encoded].join("?")
  end
end

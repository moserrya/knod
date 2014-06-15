module Knod
  class Request
    attr_reader :socket, :headers, :request_line

    def initialize(socket)
      @socket = socket
      @request_line = socket.gets
      parse_request
    end

    def parse_request
      headers = {}
      loop do
        line = socket.gets
        break if line == "\r\n"
        name, value = line.strip.split(': ')
        headers[name] = value
      end
      @headers = headers
    end

    def content_length
      headers['Content-Length'].to_i
    end

    def content_type
      headers['Content-Type']
    end

    def uri
      @uri ||= request_line.split[1]
    end

    def method
      @verb ||= request_line.split.first.upcase
    end

    def body
      @body ||= socket.read(content_length)
    end
  end
end

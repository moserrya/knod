module Knod
  class Server
    include FileUtilities

    attr_reader :server, :client, :request

    DEFAULT_PORT = 4444
    DEFAULT_WEB_ROOT = './'

    def initialize(options = {})
      port     = options.fetch(:port) { DEFAULT_PORT }
      @root    = options.fetch(:root) { DEFAULT_WEB_ROOT }
      @logging = options.fetch(:logging) { true }
      @server  = TCPServer.new('0.0.0.0', port)
    end

    def start
      log "Starting server on port #{port}"
      loop do
        Thread.start(server.accept) do |client|
          dup.accept_request_and_respond(client)
        end
      end
    end

    def accept_request_and_respond(client)
      @client = client
      @request = Request.new(client)
      log request_line
      public_send "do_#{request.method}"
    rescue => e
      log "#{e.class}: #{e.message}"
      log e.backtrace
      respond 500
    ensure
      client.close if client
    end

    def do_GET(head = false)
      path = requested_path

      if file?(path)
        File.open(path, 'rb') do |file|
          client.print file_response_header(file)
          IO.copy_stream(file, client) unless head
        end
      elsif directory?(path)
        respond(200, concat_json(path))
      else
        message = head ? '' : "\"File not found\""
        respond(404, message)
      end
    end

    def do_HEAD
      do_GET(head = true)
    end

    def do_DELETE
      path = requested_path
      delete_file(path) if file?(path)
      respond 204
    end

    def do_PUT
      write_to_path(requested_path, request.body)
      respond(200, "\"Success\"")
    end

    using HashWithPatchMerge

    def do_PATCH
      path = requested_path
      data = if file?(path)
               merge_json(read_file(path), request.body)
             else
               request.body
             end
      write_to_path(path, data)
      respond(200, "\"Success\"")
    end

    def do_POST
      path = requested_path
      create_directory(path)
      next_id = max_id_in_path(path) + 1
      write_file(join_path(path, "#{next_id}.json"), request.body)
      respond(201, "{\"id\":#{next_id}}")
    end

    def port
      server.addr[1]
    end

    private

    def write_to_path(path, data)
      directory_name = dirname(path)
      create_directory(directory_name)
      write_file(path, data)
    end

    def max_id_in_path(path)
      records = Dir.glob(path + '/*.json')
      records.map { |r| File.basename(r, '.json').to_i }.max || 0
    end

    def merge_json(file, request_body)
      file = JSON.parse(file)
      request_body = JSON.parse(request_body)
      file.patch_merge(request_body).to_json
    end

    def log(message)
      STDERR.puts message if @logging
    end

    def request_line
      request.request_line
    end

    STATUS_CODE_MAPPINGS = {
      200 => 'OK',
      201 => 'Created',
      204 => 'No Content',
      404 => 'Not Found',
      500 => 'Internal Server Error',
      501 => 'Not Implemented'
    }

    def response_header(status_code, message)
      header = "HTTP/1.1 #{status_code} #{STATUS_CODE_MAPPINGS.fetch(status_code)}\r\n"
      header << "Content-Type: application/json\r\n" unless message.empty?
      header << "Content-Length: #{message.size}\r\n"
      header << "Access-Control-Allow-Origin: *\r\n"
      header << "Connection: close\r\n\r\n"
    end

    def respond(status_code, message = '')
      client.print response_header(status_code, message)
      client.print message unless message.empty?
    end

    def file_response_header(file)
      "HTTP/1.1 200 OK\r\n" \
      "Content-Type: #{content_type(file)}\r\n" \
      "Content-Length: #{file.size}\r\n" \
      "Access-Control-Allow-Origin: *\r\n" \
      "Connection: close\r\n\r\n"
    end

    CONTENT_TYPE_MAPPING = {
      'json' => 'application/json',
      'bmp'  => 'image/bmp',
      'gif'  => 'image/gif',
      'jpg'  => 'image/jpeg',
      'png'  => 'image/png',
      'css'  => 'text/css',
      'html' => 'text/html',
      'txt'  => 'text/plain',
      'xml'  => 'text/xml'
    }

    DEFAULT_CONTENT_TYPE = 'application/octet-stream'

    def content_type(path)
      ext = file_extension(path)
      CONTENT_TYPE_MAPPING.fetch(ext) { DEFAULT_CONTENT_TYPE }
    end

    def requested_path
      local_path = URI.unescape(URI(request.uri).path)

      clean = []

      parts = local_path.split('/')

      parts.each do |part|
        next if part.empty? || part == '.'
        part == '..' ? clean.pop : clean << part
      end

      File.join(@root, *clean)
    end

    def method_missing(method_sym, *args, &block)
      if method_sym.to_s.start_with?('do_')
        respond(501, '"not implemented"')
      else
        super
      end
    end
  end
end

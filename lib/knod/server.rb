module Knod
  class Server
    using HashWithPatchMerge
    attr_reader :server, :socket, :request

    DEFAULT_PORT = 4444
    DEFAULT_WEB_ROOT = './'

    def initialize(options={})
      port     = options.fetch(:port) { DEFAULT_PORT }
      @root    = options.fetch(:root) { DEFAULT_WEB_ROOT }
      @logging = options.fetch(:logging) { true }
      @server  = TCPServer.new('0.0.0.0', port)
    end

    def start
      log "Starting server on port #{port}"
      loop do
        accept_request_and_respond
      end
    end

    def accept_request_and_respond
      @socket = server.accept
      @request = Request.new(socket)
      log request_line
      public_send "do_#{request.method}"
    rescue => e
      log "#{e.class}: #{e.message}"
      log e.backtrace
      respond_with_header 500
    ensure
      socket.close if socket
    end

    def do_GET(head=false)
      path = requested_path
      path = File.join(path, 'index.html') if File.directory?(path)

      if File.file?(path)
        File.open(path, 'rb') do |file|
          socket.print file_response_header(file)
          IO.copy_stream(file, socket) unless head
        end
      else
        message = head ? '' : "\"File not found\""
        respond_with_message(404, message)
      end
    end

    def do_HEAD
      do_GET(head=true)
    end

    def do_DELETE
      path = requested_path
      File.delete(path) if File.file?(path)
      respond_with_header(204)
    end

    def do_PUT
      write_to_path(requested_path) do |path|
        File.write(path, request.body)
      end
    end

    def do_PATCH
      write_to_path(requested_path) do |path|
        if File.file?(path)
          merged_data = merge_json(File.read(path), request.body)
          File.write(path, merged_data)
        else
          File.write(path, request.body)
        end
      end
    end

    def do_POST
      path = requested_path
      FileUtils.mkdir_p(path)
      records = Dir.glob(path + "/*.json")
      next_id = (records.map {|r| File.basename(r, ".json") }.map(&:to_i).max || 0) + 1
      File.write(File.join(path, "#{next_id}.json"), request.body)
      respond_with_message(201, "{\"id\":#{next_id}}")
    end

    def port
      server.addr[1]
    end

    private

    def write_to_path(path)
      directory = File.dirname(path)
      FileUtils.mkdir_p(directory)
      status_code = yield path
      respond_with_message(200, "\"Success\"")
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
      200 => "OK",
      201 => "Created",
      204 => "No Content",
      404 => "Not Found",
      500 => "Internal Server Error",
      501 => "Not Implemented"
    }

    def response_header(status_code, message='')
      header = "HTTP/1.1 #{status_code} #{STATUS_CODE_MAPPINGS[status_code]}\r\n"
      header << "Content-Type: application/json\r\n" unless message.empty?
      header << "Content-Length: #{message.size}\r\n"
      header << "Connection: close\r\n\r\n"
    end

    def respond_with_header(status_code)
      socket.print response_header(status_code)
    end

    def respond_with_message(status_code, message)
      socket.print response_header(status_code, message)
      socket.print message
    end

    def file_response_header(file)
      "HTTP/1.1 200 OK\r\n" <<
      "Content-Type: #{content_type(file)}\r\n" <<
      "Content-Length: #{file.size}\r\n" <<
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
      ext = File.extname(path).split('.').last
      CONTENT_TYPE_MAPPING[ext] || DEFAULT_CONTENT_TYPE
    end

    def requested_path
      local_path = URI.unescape(URI(request.uri).path)

      clean = []

      parts = local_path.split("/")

      parts.each do |part|
        next if part.empty? || part == '.'
        part == '..' ? clean.pop : clean << part
      end

      File.join(@root, *clean)
    end

    def method_missing(method_sym, *args, &block)
      if method_sym.to_s.start_with?("do_")
        respond_with_message(501, "\"not implemented\"")
      else
        super
      end
    end
  end
end

class WebMock::NetConnectNotAllowedError < Exception
  def initialize(request : HTTP::Request)
    super(help_message(request))
  end

  private def help_message(request)
    String.build do |io|
      io << "Real HTTP connections are disabled. "
      io << "Unregistered request: "
      signature(request, io)
      io << "\n\n"
      io << "You can stub this request with the following snippet:"
      io << "\n\n"
      stubbing_instructions(request, io)
      io << "\n\n"
    end
  end

  private def signature(request, io)
    io << request.method << " http://" << request.headers["Host"]
    if request.body
      io << " with body "
      request.body.inspect(io)
    end
    io << " with headers "
    headers_to_s request.headers, io
  end

  private def stubbing_instructions(request, io)
    # For the instructions we remove these two headers because they are automatically
    # included in HTTP::Client requests
    headers = request.headers.dup
    headers.delete("Content-Length")
    headers.delete("Host")

    io << "WebMock.stub(:" << request.method.downcase << ", "
    io << '"' << request.headers["Host"] << request.resource << %[").]
    io.puts

    if request.body && !headers.empty?
      io << "  with("

      if request.body
        io << "body: "
        request.body.inspect(io)
        io << ", " unless headers.empty?
      end

      unless headers.empty?
        io << "headers: "
        headers_to_s headers, io
      end
      io << ")."
      io.puts
    end

    io << %[  to_return(body: "")]
  end

  private def headers_to_s(headers, io)
    io << "{"
    headers.each_with_index do |key, values, index|
      io << ", " if index > 0
      key.name.inspect(io)
      io << " => "
      values.join(", ").inspect(io)
    end
    io << "}"
  end
end

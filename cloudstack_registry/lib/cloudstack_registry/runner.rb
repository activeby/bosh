# Copyright (c) 2003-2012 Active Cloud, Inc.

module Bosh::CloudstackRegistry
  class Runner
    include YamlHelper

    def initialize(config_file)
      Bosh::CloudstackRegistry.configure(load_yaml_file(config_file))

      @logger = Bosh::CloudstackRegistry.logger
      @http_port = Bosh::CloudstackRegistry.http_port
      @http_user = Bosh::CloudstackRegistry.http_user
      @http_password = Bosh::CloudstackRegistry.http_password
    end

    def run
      @logger.info("BOSH Cloudstack Registry starting...")
      EM.kqueue if EM.kqueue?
      EM.epoll if EM.epoll?

      EM.error_handler { |e| handle_em_error(e) }

      EM.run do
        start_http_server
      end
    end

    def stop
      @logger.info("BOSH Cloudstack Registry shutting down...")
      @http_server.stop! if @http_server
      EM.stop
    end

    def start_http_server
      @logger.info "HTTP server is starting on port #{@http_port}..."
      @http_server = Thin::Server.new("0.0.0.0", @http_port, :signals => false) do
        Thin::Logging.silent = true
        map "/" do
          run Bosh::CloudstackRegistry::ApiController.new
        end
      end
      @http_server.start!
    end

    private

    def handle_em_error(e)
      @logger.info(e.to_s)
      @logger.send(level, e.to_s)
      if e.respond_to?(:backtrace) && e.backtrace.respond_to?(:join)
        @logger.send(level, e.backtrace.join("\n"))
      end
      stop
    end

  end
end
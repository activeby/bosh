# Copyright (c) 2003-2012 Active Cloud, Inc.

module Bosh::CloudstackRegistry

  class Error < StandardError
    def self.code(code = 500)
      define_method(:code) { code }
    end
  end

  class FatalError < Error; end

  class ConfigError < Error; end
  class ConnectionError < Error; end

  class CloudstackError < Error; end

  class ServerError < Error; end
  class ServerNotFound < Error; code(404); end
end

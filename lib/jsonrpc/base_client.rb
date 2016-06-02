require 'securerandom'
require 'uri'

module JSONRPC
  class BaseClient
    def make_id
      SecureRandom.hex(16)
    end

    def initialize(url, opts = {})
      @url = ::URI.parse(url).to_s
      @helper = ::JSONRPC::Helper.new(opts)
    end
  end
end

require 'securerandom'
require 'uri'

module JSONRPC
  class BaseClient
    JSON_RPC_VERSION = '2.0'

    def make_id
      SecureRandom.hex(16)
    end

    def initialize(url, opts = {})
      @url = ::URI.parse(url).to_s
      @helper = ::JSONRPC::Helper.new(opts)
    end
  end
end

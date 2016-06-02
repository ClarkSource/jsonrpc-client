require 'jsonrpc/client'
require 'jsonrpc/batch_client'

module JSONRPC
  JSON_RPC_VERSION = '2.0'

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger
  end
end

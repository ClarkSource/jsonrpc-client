require 'jsonrpc/client'
require 'jsonrpc/batch_client'

module JSONRPC
  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger
  end
end

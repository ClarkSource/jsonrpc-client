require 'jsonrpc/client'

module JSONRPC
  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger
  end
end

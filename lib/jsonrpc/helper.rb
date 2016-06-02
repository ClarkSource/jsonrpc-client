require 'faraday'

module JSONRPC
  class Helper
    def initialize(options)
      @options = options
      @options[:content_type] ||= 'application/json'
      @connection = @options.delete(:connection)
    end

    def options(additional_options = {})
      additional_options.merge(@options)
    end

    def connection
      @connection ||= ::Faraday.new do |connection|
        connection.response :logger, ::JSONRPC.logger
        connection.adapter ::Faraday.default_adapter
      end
    end
  end
end

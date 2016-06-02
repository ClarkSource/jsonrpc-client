require 'jsonrpc/base_client'

module JSONRPC
  class BatchClient < BaseClient
    attr_reader :batch

    def initialize(url, opts = {})
      super
      @batch = []
      @alive = true
      yield self
      send_batch
      @alive = false
    end

    def invoke(method, args = nil, options = {})
      if @alive
        request = ::JSONRPC::Request.new(method, args)
        push_batch_request(request)
      else
        super
      end
    end

  private
    def send_batch_request(batch)
      post_data = ::JSON.generate(batch)
      resp = @helper.connection.post(@url, post_data, @helper.options)
      if resp.nil? || resp.body.nil? || resp.body.empty?
        raise ::JSONRPC::Error::InvalidResponse.new
      end

      resp.body
    end

    def process_batch_response(responses)
      responses.each do |resp|
        saved_response = @batch.map { |r| r[1] }.select { |r| r.id == resp['id'] }.first
        raise ::JSONRPC::Error::InvalidResponse.new if saved_response.nil?
        saved_response.populate!(resp)
      end
    end

    def push_batch_request(request)
      request.id = make_id
      response = ::JSONRPC::Response.new(request.id)
      @batch << [request, response]
      response
    end

    def send_batch
      batch = @batch.map(&:first) # get the requests
      response = send_batch_request(batch)

      begin
        responses = ::JSON.parse(response)
      rescue
        raise ::JSONRPC::Error::InvalidJSON.new(json)
      end

      process_batch_response(responses)
      @batch = []
    end
  end
end

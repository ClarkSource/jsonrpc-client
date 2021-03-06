require 'json'
require 'jsonrpc'
require 'jsonrpc/base_client'
require 'jsonrpc/request'
require 'jsonrpc/helper'
require 'jsonrpc/response'
require 'jsonrpc/error'
require 'jsonrpc/version'

module JSONRPC
  class Client < BaseClient
    def authenticate_with_token(token)
      additional_root_params[:token] = token
    end

    def invoke(method, args, options = {})
      resp = send_single_request(method.to_s, args, options)

      begin
        data = ::JSON.parse(resp)
      rescue
        raise ::JSONRPC::Error::InvalidJSON.new(resp)
      end

      process_single_response(data)
    rescue => e
      e.extend(::JSONRPC::Error)
      raise
    end

    private
    def send_single_request(method, args, options)
      request = JSONRPC::Request.new(method, args, make_id, additional_root_params)
      resp = @helper.connection.post(@url, request.to_json, @helper.options(options))

      if resp.nil? || resp.body.nil? || resp.body.empty?
        raise ::JSONRPC::Error::InvalidResponse.new
      end

      resp.body
    end

    def process_single_response(data)
      raise ::JSONRPC::Error::InvalidResponse.new unless valid_response?(data)

      if data['error']
        code = data['error']['code']
        msg = data['error']['message']
        raise ::JSONRPC::Error::ServerError.new(code, msg)
      end

      data['result']
    end

    def valid_response?(data)
      return false if !data.is_a?(::Hash)
      return false if data['jsonrpc'] != JSON_RPC_VERSION
      return false if !data.has_key?('id')
      return false if data.has_key?('error') && data.has_key?('result')

      if data.has_key?('error')
        if !data['error'].is_a?(::Hash) || !data['error'].has_key?('code') || !data['error'].has_key?('message')
          return false
        end

        if !data['error']['code'].is_a?(::Fixnum) || !data['error']['message'].is_a?(::String)
          return false
        end
      end

      true
    rescue
      false
    end

    def additional_root_params
      @additional_root_params ||= {}
    end
  end
end

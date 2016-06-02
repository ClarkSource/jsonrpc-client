module JSONRPC
  class Request
    attr_accessor :method, :params, :id

    def initialize(method, params, id = nil)
      @method = method
      @params = params
      @id = id
    end

    def to_h
      return_hash = {
        jsonrpc: JSONRPC::JSON_RPC_VERSION,
        method: method,
        params: params,
        id: id
      }

      return_hash.delete :params unless should_include_params?

      return_hash
    end

    def to_json(*_)
      JSON.generate(to_h)
    end

    private
    def should_include_params?
      (params.kind_of?(Array) || params.kind_of?(Hash)) && !params.empty?
    end
  end
end

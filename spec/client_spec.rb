require 'spec_helper'

describe JSONRPC::Client do
  BOILERPLATE = {'jsonrpc' => '2.0', 'id' => "some-id"}

  let(:connection) { double('connection') }

  before(:each) do
    @resp_mock = double('http_response')
    allow_any_instance_of(JSONRPC::BaseClient).to receive(:make_id).and_return("some-id")
  end

  describe "#invoke" do
    let(:expected) { JSON.generate({
       'jsonrpc' => '2.0',
       'method'  => 'foo',
       'params'  => [1,2,3],
       'id'      => "some-id"
      })
    }

    before(:each) do
      response = JSON.generate(BOILERPLATE.merge({'result' => 42}))
      expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
      @client = JSONRPC::Client.new(SPEC_URL, :connection => connection)
    end

    context "when using an array of args" do
      it "sends a request with the correct method and args" do
        expect(connection).to receive(:post).with(SPEC_URL, expected, {:content_type => 'application/json'}).and_return(@resp_mock)
        expect(@client.invoke('foo', [1, 2, 3])).to eq(42)
      end
    end

    context "with headers" do
      it "adds additional headers" do
        expect(connection).to receive(:post).with(SPEC_URL, expected, {:content_type => 'application/json', "X-FOO" => "BAR"}).and_return(@resp_mock)
        expect(@client.invoke('foo', [1, 2, 3], "X-FOO" => "BAR")).to eq(42)
      end
    end
  end

  describe "sending a single request" do
    context "when using positional parameters" do
      before(:each) do
        @expected = JSON.generate({
                     'jsonrpc' => '2.0',
                     'method'  => 'foo',
                     'params'  => [1,2,3],
                     'id'      => "some-id"
        })
      end
      it "sends a valid JSON-RPC request and returns the result" do
        response = JSON.generate(BOILERPLATE.merge({'result' => 42}))
        expect(connection).to receive(:post).with(SPEC_URL, @expected, {:content_type => 'application/json'}).and_return(@resp_mock)
        expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
        client = JSONRPC::Client.new(SPEC_URL, :connection => connection)
        expect(client.invoke('foo', [1,2,3])).to eq(42)
      end

      it "sends a valid JSON-RPC request with custom options" do
        response = JSON.generate(BOILERPLATE.merge({'result' => 42}))
        expect(connection).to receive(:post).with(SPEC_URL, @expected, {:content_type => 'application/json', :timeout => 10000}).and_return(@resp_mock)
        expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
        client = JSONRPC::Client.new(SPEC_URL, :timeout => 10000, :connection => connection)
        expect(client.invoke('foo', [1,2,3])).to eq(42)
      end

      it "sends a valid JSON-RPC request with custom content_type" do
        response = JSON.generate(BOILERPLATE.merge({'result' => 42}))
        expect(connection).to receive(:post).with(SPEC_URL, @expected, {:content_type => 'application/json-rpc', :timeout => 10000}).and_return(@resp_mock)
        expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
        client = JSONRPC::Client.new(SPEC_URL, :timeout => 10000, :content_type => 'application/json-rpc', :connection => connection)
        expect(client.invoke('foo', [1,2,3])).to eq(42)
      end
    end
  end
end

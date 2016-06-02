require 'spec_helper'

describe JSONRPC::BatchClient do
  BOILERPLATE = { 'jsonrpc' => '2.0', 'id' => "1" }

  let(:connection) { double('connection') }

  before(:each) do
    @resp_mock = double('http_response')
  end

  describe "sending a batch request" do
    it "sends a valid JSON-RPC batch request and puts the results in the response objects" do
      batch = JSON.generate([
        {"jsonrpc" => "2.0", "method" => "sum", "params" => [1,2,4], "id" => "some-id-1"},
        {"jsonrpc" => "2.0", "method" => "subtract", "params" => [42,23], "id" => "some-id-2"},
        {"jsonrpc" => "2.0", "method" => "foo_get", "params" => {"name" => "myself"}, "id" => "some-id-3"},
        {"jsonrpc" => "2.0", "method" => "get_data", "id" => "some-id-4"}
        ])

        response = JSON.generate([
          {"jsonrpc" => "2.0", "result" => 7, "id" => "some-id-1"},
          {"jsonrpc" => "2.0", "result" => 19, "id" => "some-id-2"},
          {"jsonrpc" => "2.0", "error" => {"code" => -32601, "message" => "Method not found."}, "id" => "some-id-3"},
          {"jsonrpc" => "2.0", "result" => ["hello", 5], "id" => "some-id-4"}
          ])

          allow_any_instance_of(JSONRPC::BaseClient).to receive(:make_id).and_return('some-id-1', 'some-id-2', 'some-id-3', 'some-id-4')
          expect(connection).to receive(:post).with(SPEC_URL, batch, {:content_type => 'application/json'}).and_return(@resp_mock)
          expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
          client = JSONRPC::Client.new(SPEC_URL, :connection => connection)

          sum = subtract = foo = data = nil
          client = JSONRPC::BatchClient.new(SPEC_URL, :connection => connection) do |batch|
            sum = batch.invoke('sum', [1,2,4])
            subtract = batch.invoke('subtract', [42,23])
            foo = batch.invoke('foo_get', { 'name' => 'myself' })
            data = batch.invoke('get_data')
          end

          expect(sum.succeeded?).to be_truthy
          expect(sum.is_error?).to be_falsey
          expect(sum.result).to eq(7)

          expect(subtract.result).to eq(19)

          expect(foo.is_error?).to be_truthy
          expect(foo.succeeded?).to be_falsey
          expect(foo.error['code']).to eq(-32601)

          expect(data.result).to eq(['hello', 5])


          expect { client.sum(1, 2) }.to raise_error(NoMethodError)
        end
      end

    end

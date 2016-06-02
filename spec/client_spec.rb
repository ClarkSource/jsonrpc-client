require 'spec_helper'

module JSONRPC
  describe Client do
    BOILERPLATE = {'jsonrpc' => '2.0', 'id' => 1}

    let(:connection) { double('connection') }

    before(:each) do
      @resp_mock = double('http_response')
      allow(Base).to receive(:make_id).and_return(1)
    end

    after(:each) do
    end

    describe "hidden methods" do
      it "should reveal inspect" do
        expect(Client.new(SPEC_URL).inspect).to match /JSONRPC::Client/
      end

      it "should reveal to_s" do
        expect(Client.new(SPEC_URL).to_s).to match /JSONRPC::Client/
      end
    end

    describe "#invoke" do
      let(:expected) { JSON.generate({
         'jsonrpc' => '2.0',
         'method'  => 'foo',
         'params'  => [1,2,3],
         'id'      => 1
        })
      }

      before(:each) do
        response = JSON.generate(BOILERPLATE.merge({'result' => 42}))
        expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
        @client = Client.new(SPEC_URL, :connection => connection)
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
                       'id'      => 1
          })
        end
        it "sends a valid JSON-RPC request and returns the result" do
          response = JSON.generate(BOILERPLATE.merge({'result' => 42}))
          expect(connection).to receive(:post).with(SPEC_URL, @expected, {:content_type => 'application/json'}).and_return(@resp_mock)
          expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
          client = Client.new(SPEC_URL, :connection => connection)
          expect(client.foo(1,2,3)).to eq(42)
        end

        it "sends a valid JSON-RPC request with custom options" do
          response = JSON.generate(BOILERPLATE.merge({'result' => 42}))
          expect(connection).to receive(:post).with(SPEC_URL, @expected, {:content_type => 'application/json', :timeout => 10000}).and_return(@resp_mock)
          expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
          client = Client.new(SPEC_URL, :timeout => 10000, :connection => connection)
          expect(client.foo(1,2,3)).to eq(42)
        end

        it "sends a valid JSON-RPC request with custom content_type" do
          response = JSON.generate(BOILERPLATE.merge({'result' => 42}))
          expect(connection).to receive(:post).with(SPEC_URL, @expected, {:content_type => 'application/json-rpc', :timeout => 10000}).and_return(@resp_mock)
          expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
          client = Client.new(SPEC_URL, :timeout => 10000, :content_type => 'application/json-rpc', :connection => connection)
          expect(client.foo(1,2,3)).to eq(42)
        end
      end
    end

    describe "sending a batch request" do
      it "sends a valid JSON-RPC batch request and puts the results in the response objects" do
        batch = JSON.generate([
          {"jsonrpc" => "2.0", "method" => "sum", "params" => [1,2,4], "id" => "1"},
          {"jsonrpc" => "2.0", "method" => "subtract", "params" => [42,23], "id" => "2"},
          {"jsonrpc" => "2.0", "method" => "foo_get", "params" => [{"name" => "myself"}], "id" => "5"},
          {"jsonrpc" => "2.0", "method" => "get_data", "id" => "9"}
        ])

        response = JSON.generate([
          {"jsonrpc" => "2.0", "result" => 7, "id" => "1"},
          {"jsonrpc" => "2.0", "result" => 19, "id" => "2"},
          {"jsonrpc" => "2.0", "error" => {"code" => -32601, "message" => "Method not found."}, "id" => "5"},
          {"jsonrpc" => "2.0", "result" => ["hello", 5], "id" => "9"}
        ])

        allow(Base).to receive(:make_id).and_return('1', '2', '5', '9')
        expect(connection).to receive(:post).with(SPEC_URL, batch, {:content_type => 'application/json'}).and_return(@resp_mock)
        expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
        client = Client.new(SPEC_URL, :connection => connection)

        sum = subtract = foo = data = nil
        client = BatchClient.new(SPEC_URL, :connection => connection) do |batch|
          sum = batch.sum(1,2,4)
          subtract = batch.subtract(42,23)
          foo = batch.foo_get('name' => 'myself')
          data = batch.get_data
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
end

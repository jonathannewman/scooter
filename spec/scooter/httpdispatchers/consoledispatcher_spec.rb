require 'spec_helper'

module Scooter

  describe HttpDispatchers::ConsoleDispatcher do

    let(:host) {double('host')}
    let(:credentials) { { login: username, password: password} }
    let(:username) {'Ziggy'}
    let(:password) {'Stardust'}
    let(:mock_page) {double('mock_page')}

    subject { HttpDispatchers::ConsoleDispatcher.new(host, credentials) }

    context 'with a beaker host passed in' do
      let(:logger) { double('logger')}
      unixhost = { roles:     ['test_role'],
                   'platform' => 'debian-7-x86_64' }
      let(:host) { Beaker::Host.create('test.com', unixhost, {:logger => logger}) }
      before do
        allow_any_instance_of(Beaker::Http::FaradayBeakerLogger).to receive(:info) { true }
        allow_any_instance_of(Beaker::Http::FaradayBeakerLogger).to receive(:debug) { true }
        expect(OpenSSL::PKey).to receive(:read).and_return('Pkey')
        expect(OpenSSL::X509::Certificate).to receive(:new).and_return('client_cert')
        allow_any_instance_of(HttpDispatchers::HttpDispatcher).to receive(:get_host_cert) {'host cert'}
        allow_any_instance_of(HttpDispatchers::HttpDispatcher).to receive(:get_host_private_key) {'key file'}
        allow_any_instance_of(HttpDispatchers::HttpDispatcher).to receive(:get_host_cacert) {'cert file'}
        expect(subject).to be_kind_of(HttpDispatchers::ConsoleDispatcher)
      end

      context '"signin with a page that returns a token' do
        before do
          index = subject.connection.builder.handlers.index(Faraday::Adapter::NetHttp)
          subject.connection.builder.swap(index, Faraday::Adapter::Test) do |stub|
            head = {"server"=>"nginx/1.8.1", 
                    "date"=>"Tue, 29 Nov 2016 22:05:41 GMT", 
                    "content-length"=>"0", 
                    "connection"=>"close", 
                    "set-cookie"=>"JSESSIONID=b05e9b11-5e9f-4d6a-9faf-e28a0415197d; Path=/; Secure; HttpOnly, rememberMe=deleteMe; Path=/auth; Max-Age=0; Expires=Mon, 28-Nov-2016 22:05:41 GMT, pl_ssti=0CeHhpz5PPLna7kpaEMcTHjJ62z9eizHTzsxEXNK8W20;Secure;Path=/", 
                    "location"=>"/", 
                    "x-frame-options"=>"DENY"}
            stub.post('/auth/login', "username=#{username}&password=#{password}") {[200, head, '']}
            stub.get('/') {[200, {}, '']}
          end
        end

        it 'sends the credentials' do
          expect{subject.signin}.to_not raise_error
        end

        it 'sets the token in the header' do
          subject.signin
          expect(subject.connection.headers['Cookie']).to include('pl_ssti=')
        end
      end
    end
  end
end

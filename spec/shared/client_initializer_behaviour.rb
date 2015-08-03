# encoding: utf-8

shared_examples 'a client initializer' do
  def subdomain
    if rest?
      'rest'
    else
      'realtime'
    end
  end

  def protocol
    if rest?
      'http'
    else
      'ws'
    end
  end

  def rest?
    subject.kind_of?(Ably::Rest::Client)
  end

  context 'with invalid arguments' do
    context 'empty hash' do
      let(:client_options) { Hash.new }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key is missing/)
      end
    end

    context 'nil' do
      let(:client_options) { nil }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /Options Hash is expected/)
      end
    end

    context 'key: "invalid"' do
      let(:client_options) { { key: 'invalid' } }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key is invalid/)
      end
    end

    context 'key: "invalid:asdad"' do
      let(:client_options) { { key: 'invalid:asdad' } }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key is invalid/)
      end
    end

    context 'key and key_name' do
      let(:client_options) { { key: 'appid.keyuid:keysecret', key_name: 'invalid' } }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key and key_name or key_secret are mutually exclusive/)
      end
    end

    context 'key and key_secret' do
      let(:client_options) { { key: 'appid.keyuid:keysecret', key_secret: 'invalid' } }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key and key_name or key_secret are mutually exclusive/)
      end
    end

    context 'client_id as only option' do
      let(:client_options) { { client_id: 'valid' } }

      it 'requires a valid key' do
        expect { subject }.to raise_error(ArgumentError, /client_id cannot be provided without a complete API key/)
      end
    end
  end

  context 'with valid arguments' do
    let(:default_options) { { key: 'appid.keyuid:keysecret' } }
    let(:client_options)  { default_options }

    context 'key only' do
      it 'connects to the Ably service' do
        expect { subject }.to_not raise_error
      end
    end

    context 'key_name and key_secret', api_private: true do
      let(:client_options) { { key_name: 'id', key_secret: 'secret' } }

      it 'constructs a key' do
        expect(subject.auth.key).to eql('id:secret')
      end
    end

    context 'with a string key instead of options hash' do
      let(:client_options) { 'app.key:secret' }

      it 'sets the key' do
        expect(subject.auth.key).to eql(client_options)
      end

      it 'sets the key_name' do
        expect(subject.auth.key_name).to eql('app.key')
      end

      it 'sets the key_secret' do
        expect(subject.auth.key_secret).to eql('secret')
      end
    end

    context 'with a string token key instead of options hash' do
      let(:client_options) { 'app.kjhkasjhdsakdh127g7g1271' }

      it 'sets the token' do
        expect(subject.auth.token).to eql(client_options)
      end
    end

    context 'with token' do
      let(:client_options) { { token: 'token' } }

      it 'sets the token' do
        expect(subject.auth.token).to eql('token')
      end
    end

    context 'with token_details' do
      let(:client_options) { { token_details: Ably::Models::TokenDetails.new(token: 'token') } }

      it 'sets the token' do
        expect(subject.auth.token).to eql('token')
      end
    end

    context 'endpoint' do
      it 'defaults to production' do
        expect(subject.endpoint.to_s).to eql("#{protocol}s://#{subdomain}.ably.io")
      end

      context 'with environment option' do
        let(:client_options) { default_options.merge(environment: 'sandbox') }

        it 'uses an alternate endpoint' do
          expect(subject.endpoint.to_s).to eql("#{protocol}s://sandbox-#{subdomain}.ably.io")
        end
      end
    end

    context 'tls' do
      context 'set to false' do
        let(:client_options) { default_options.merge(tls: false) }

        it 'uses plain text' do
          expect(subject.use_tls?).to eql(false)
        end

        it 'uses HTTP' do
          expect(subject.endpoint.to_s).to eql("#{protocol}://#{subdomain}.ably.io")
        end
      end

      it 'defaults to TLS' do
        expect(subject.use_tls?).to eql(true)
      end
    end

    context 'logger' do
      context 'default' do
        it 'uses Ruby Logger' do
          expect(subject.logger.logger).to be_a(::Logger)
        end

        it 'specifies Logger::WARN log level' do
          expect(subject.logger.log_level).to eql(::Logger::WARN)
        end
      end

      context 'with log_level :none' do
        let(:client_options) { default_options.merge(log_level: :none) }

        it 'silences all logging with a NilLogger' do
          expect(subject.logger.logger.class).to eql(Ably::Models::NilLogger)
          expect(subject.logger.log_level).to eql(:none)
        end
      end

      context 'with custom logger and log_level' do
        let(:custom_logger) do
          Class.new do
            extend Forwardable
            def initialize
              @logger = Logger.new(STDOUT)
            end
            def_delegators :@logger, :fatal, :error, :warn, :info, :debug, :level, :level=
          end
        end
        let(:client_options) { default_options.merge(logger: custom_logger.new, log_level: Logger::DEBUG) }

        it 'uses the custom logger' do
          expect(subject.logger.logger.class).to eql(custom_logger)
        end

        it 'sets the custom log level' do
          expect(subject.logger.log_level).to eql(Logger::DEBUG)
        end
      end
    end
  end

  context 'delegators' do
    let(:client_options) { 'app.key:secret' }

    it 'delegates :client_id to .auth' do
      expect(subject.auth).to receive(:client_id).and_return('john')
      expect(subject.client_id).to eql('john')
    end

    it 'delegates :auth_options to .auth' do
      expect(subject.auth).to receive(:auth_options).and_return({ option: 1 })
      expect(subject.auth_options).to eql({ option: 1 })
    end
  end
end

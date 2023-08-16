# frozen_string_literal: true

require 'ruby_claim_evidence_api/external_api/response'
module Fakes
  class ClaimEvidenceService
    TOKEN_SECRET = ENV['JWT_SECRET']
    TOKEN_ISSUER = ENV['JWT_ISSUER']
    BASE_URL = ENV['CLAIM_EVIDENCE_API_URL']
    SERVER = '/api/v1/rest'
    DOCUMENT_TYPES_ENDPOINT = '/documenttypes'
    # this must start with http://
    HTTP_PROXY = ENV['DEVVPN_PROXY']
    CERT_LOCATION = ENV['SSL_CERT_FILE']
    KEY_LOCATION = ENV['CLAIM_EVIDENCE_KEY_FILE']
    CERT_PASSWORD = ENV['CLAIM_EVIDENCE_CERT_PASSPHRASE']
    HEADERS = {
      "Content-Type": 'application/json',
      "Accept": '*/*'
    }.freeze
    CREDENTIALS = Aws::Credentials.new(
      ENV['AWS_ACCESS_KEY_ID'],
      ENV['AWS_SECRET_ACCESS_KEY']
    )
    REGION = ENV['AWS_DEFAULT_REGION']
    AWS_COMPREHEND_SCORE = ENV['AWS_COMPREHEND_SCORE']

    class << self
      def document_types_request
        {
          headers: HEADERS,
          endpoint: DOCUMENT_TYPES_ENDPOINT,
          method: :get
        }
      end

      def ocr_document_request(doc_uuid)
        {
          headers: HEADERS.merge("Content-Type": 'application/x-www-form-urlencoded'),
          endpoint: "/files/#{doc_uuid}/data/ocr",
          method: :get
        }
      end

      def document_types
        response = if HTTP_PROXY
                     use_faraday(document_types_request)
                   else
                     JSON.parse(IO.binread(File.join(Rails.root, 'lib', 'data', 'DOCUMENT_TYPES.json')))
                   end

        if HTTP_PROXY
          response.body['documentTypes']
        else
          response['documentTypes']
        end
      end

      def alt_document_types
        response = if HTTP_PROXY
                     use_faraday(document_types_request)
                   else
                     JSON.parse(IO.binread(File.join(Rails.root, 'lib', 'data', 'DOCUMENT_TYPES.json')))
                   end

        if HTTP_PROXY
          response.body['alternativeDocumentTypes']
        else
          response['alternativeDocumentTypes']
        end
      end

      def get_ocr_document(doc_uuid)
        response = if HTTP_PROXY
                     use_faraday(ocr_document_request(doc_uuid))
                   else
                     JSON.parse(IO.binread(File.join(Rails.root, 'lib', 'data', 'OCR_DOCUMENT.json')))
                   end

        if HTTP_PROXY
          response.body['currentVersion']['file']['text']
        else
          response['currentVersion']['file']['text']
        end
      end

      def use_faraday(endpoint:, query: {}, headers: {}, method: :get, body: nil)

        token = generate_jwt_token
        
        url = URI::DEFAULT_PARSER.escape(BASE_URL)
        # The certs fail to successfully connect so SSL verification is disabled, but they still need to be present
        # Followed steps at https://github.com/department-of-veterans-affairs/bip-vefs-claimevidence/wiki/Claim-Evidence-Local-Developer-Environment-Setup-Guide#testing-with-postman
        # To set this up and get files
        client_cert = OpenSSL::X509::Certificate.new(File.read(CERT_LOCATION))
        client_key = OpenSSL::PKey::RSA.new(File.read(KEY_LOCATION),
                                            CERT_PASSWORD)
        # Have to use Faraday as HTTPI does not allow proxies to be setup correctly
        # Have to start devvpn for this to work
        conn = Faraday.new(
          url: url,
          headers: headers.merge(Authorization: "Bearer #{token}"),
          proxy: HTTP_PROXY,
          ssl: {
            client_cert: client_cert,
            client_key: client_key,
            verify: !ApplicationController.dependencies_faked?
          }
        ) do |c|
          c.response :json
          c.adapter Faraday.default_adapter
        end

        sleep 1
        MetricsService.record("api.fakes.notifications.claim.evidence #{method.to_s.upcase} request to #{url} with token: #{token}",
                              service: :claim_evidence,
                              name: endpoint) do
          case method
          when :get
            response = conn.get(SERVER + endpoint, query)
            service_response = ExternalApi::Response.new(response)
            fail service_response.error if service_response.error.present?

            service_response
          when :post
            response = conn.post(SERVER + endpoint, body)
            service_response = ExternalApi::Response.new(response)
            fail service_response.error if service_response.error.present?

            service_response
          else
            fail NotImplementedError
          end
        end
      end

      def generate_jwt_token
        header = {
          typ: 'JWT',
          alg: 'HS256'
        }
        current_timestamp = DateTime.now.strftime('%Q').to_i / 1000.floor
        data = {
          jti: "",
          iat: current_timestamp,
          iss: TOKEN_ISSUER,
          applicationId: TOKEN_ISSUER,
          userID: "",
          stationID: ""
        }
        stringified_header = header.to_json.encode('UTF-8')
        encoded_header = Encoder.encode64(stringified_header)
        stringified_data = data.to_json.encode('UTF-8')
        encoded_data = Encoder.encode64(stringified_data)
        token = "#{encoded_header}.#{encoded_data}"
        signature = OpenSSL::HMAC.digest('SHA256', TOKEN_SECRET, token)
        signature = Encoder.encode64(signature)
        "#{token}.#{signature}"
      end

      def aws_client
        @aws_client ||= Aws::Comprehend::Client.new(
          region: REGION,
          credentials: CREDENTIALS
        )
      end

      def aws_stub_client
        @aws_stub_client ||= Aws::Comprehend::Client.new(
          region: REGION,
          credentials: CREDENTIALS,
          stub_responses: true
        )
      end

      def get_key_phrases(ocr_data, stub_response: false)
        key_phrase_parameters = {
          text: ocr_data,
          language_code: 'en'
        }
        if stub_response == true
          aws_stub_client.detect_key_phrases(key_phrase_parameters).key_phrases
        else
          aws_client.detect_key_phrases(key_phrase_parameters).key_phrases
        end
      end

      def filter_key_phrases_by_score(key_phrases)
        key_phrases.filter_map do |key_phrase|
          key_phrase[:text] if !key_phrase[:score].nil? && key_phrase[:score] >= AWS_COMPREHEND_SCORE
        end
      end

      def get_key_phrases_from_document(doc_uuid, stub_response: false)
        ocr_data = get_ocr_document(doc_uuid)
        key_phrases = get_key_phrases(ocr_data, stub_response)
        filter_key_phrases_by_score(key_phrases)
      end
    end
  end
end

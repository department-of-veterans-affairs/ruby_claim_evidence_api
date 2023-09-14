# frozen_string_literal: true

require 'pry'
require 'httpi'
require 'active_support/all'
require 'ruby_claim_evidence_api/external_api/response.rb'
require 'aws-sdk'
require 'base64'

module ExternalApi
  # Establishes connection between Claims Evidence API, AWS, and Caseflow
  # Handles HTTP Requests, Errors, and business logic to Claims Evidence API
  class ClaimEvidenceService
    # Environment Variables
    TOKEN_SECRET = ENV['CLAIM_EVIDENCE_SECRET']
    TOKEN_ISSUER = ENV['CLAIM_EVIDENCE_ISSUER']
    TOKEN_USER = ENV['CLAIM_EVIDENCE_VBMS_USER']
    TOKEN_STATION_ID = ENV['CLAIM_EVIDENCE_STATION_ID']
    BASE_URL = ENV['CLAIM_EVIDENCE_API_URL']
    CERT_FILE_LOCATION = ENV['SSL_CERT_FILE']
    SERVER = 'api/v1/rest'
    DOCUMENT_TYPES_ENDPOINT = '/documenttypes'
    HEADERS = {
      "Content-Type": 'application/json',
      "Accept": '*/*'
    }.freeze
    REGION = ENV['AWS_REGION']
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
          headers: HEADERS,
          endpoint: "/files/#{doc_uuid}/data/ocr",
          method: :get
        }
      end

      def document_types
        send_ce_api_request(document_types_request).body['documentTypes']
      end

      def alt_document_types
        send_ce_api_request(document_types_request).body['alternativeDocumentTypes']
      end

      def get_ocr_document(doc_uuid)
        send_ce_api_request(ocr_document_request(doc_uuid)).body['currentVersion']['file']['text']
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def send_ce_api_request(endpoint:, query: {}, headers: {}, method: :get, body: nil)
        jwt_token = generate_jwt_token

        url = URI::DEFAULT_PARSER.escape(BASE_URL + SERVER + endpoint)
        request = HTTPI::Request.new(url)
        request.query = query
        request.open_timeout = 30
        request.read_timeout = 30
        request.body = body.to_json unless body.nil?
        request.auth.ssl.ssl_version  = :TLSv1_2
        request.auth.ssl.ca_cert_file = CERT_FILE_LOCATION
        request.auth.ssl.cert_file = ENV['BGS_CERT_LOCATION']
        request.auth.ssl.cert_key_file = ENV['BGS_KEY_LOCATION']
        request.headers = headers.merge(Authorization: "Bearer #{jwt_token}")

        sleep 1

        # Check to see if MetricsService class exists. Required for Caseflow
        if Object.const_defined?('MetricsService')
          MetricsService.record("api.claim.evidence #{method.to_s.upcase} request to #{url}",
                                service: :claim_evidence,
                                name: endpoint) do
            case method
            when :get
              begin
                response = HTTPI.get(request)
                service_response = ExternalApi::Response.new(response)
              rescue
                service_response = ExternalApi::Response.new(response)
                fail service_response.error if service_response.error.present?
              end
              service_response
            else
              fail NotImplementedError
            end
          end
        else
          case method
          when :get
            begin
              response = HTTPI.get(request)
              service_response = ExternalApi::Response.new(response)
            rescue
              service_response = ExternalApi::Response.new(response)
              fail service_response.error if service_response.error.present?
            end
            service_response
          else
            fail NotImplementedError
          end
        end
      end

      def aws_client
        @aws_client ||= Aws::Comprehend::Client.new(
          region: REGION,
        )
      end

      def aws_stub_client
        @aws_stub_client ||= Aws::Comprehend::Client.new(
          region: REGION,
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
          key_phrase[:text] if !key_phrase[:score].nil? && key_phrase[:score] >= AWS_COMPREHEND_SCORE.to_f
        end
      end

      def get_key_phrases_from_document(doc_uuid, stub_response: false)
        ocr_data = get_ocr_document(doc_uuid)

        return unless ocr_data.present?

        key_phrases = get_key_phrases(ocr_data, stub_response: stub_response)
        filter_key_phrases_by_score(key_phrases)
      end

      private

      def generate_jwt_token
        header = {
          typ: 'JWT',
          alg: 'HS256'
        }
        current_timestamp = DateTime.now.strftime('%Q').to_i / 1000.floor
        data = {
          jti: SecureRandom.uuid,
          iat: current_timestamp,
          iss: TOKEN_ISSUER,
          applicationId: TOKEN_ISSUER,
          userID: TOKEN_USER,
          stationID: TOKEN_STATION_ID
        }
        stringified_header = header.to_json.encode('UTF-8')
        encoded_header = base64url(stringified_header)
        stringified_data = data.to_json.encode('UTF-8')
        encoded_data = base64url(stringified_data)
        token = "#{encoded_header}.#{encoded_data}"
        signature = OpenSSL::HMAC.digest('SHA256', TOKEN_SECRET, token)

        "#{token}.#{base64url(signature)}"
      end

      def base64url(source)
        encoded_source = Base64.encode64(source)
        encoded_source = encoded_source.sub(/=+$/, '')
        encoded_source = encoded_source.tr('+', '-')
        encoded_source.tr('/', '_')
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end

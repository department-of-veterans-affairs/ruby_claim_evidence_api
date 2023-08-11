# frozen_string_literal: true

require 'pry'
require 'httpi'
require 'active_support/all'
require 'ruby_claim_evidence_api/external_api/response.rb'
require 'aws-sdk'

module ExternalApi
  # Establishes connection between Claims Evidence API, AWS, and Caseflow
  # Handles HTTP Requests, Errors, and business logic to Claims Evidnece API
  class ClaimEvidenceService
    # Environment Variables
    JWT_TOKEN = ENV['CLAIM_EVIDENCE_JWT_TOKEN']
    BASE_URL = ENV['CLAIM_EVIDENCE_API_URL']
    CERT_FILE_LOCATION = ENV['SSL_CERT_FILE']
    SERVER = '/api/v1/rest'
    DOCUMENT_TYPES_ENDPOINT = '/documenttypes'
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
        url = URI::DEFAULT_PARSER.escape(BASE_URL + SERVER + endpoint)
        request = HTTPI::Request.new(url)
        request.query = query
        request.open_timeout = 30
        request.read_timeout = 30
        request.body = body.to_json unless body.nil?
        request.auth.ssl.ssl_version  = :TLSv1_2
        request.auth.ssl.ca_cert_file = CERT_FILE_LOCATION
        request.headers = headers.merge(Authorization: "Bearer " + JWT_TOKEN)

        sleep 1

        # Check to see if MetricsService class exists. Required for Caseflow
        if Object.const_defined?('MetricsService')
          MetricsService.record("api.notifications.claim.evidence #{method.to_s.upcase} request to #{url}",
                                service: :claim_evidence,
                                name: endpoint) do
            case method
            when :get
              response = HTTPI.get(request)
              service_response = ExternalApi::Response.new(response)
              fail service_response.error if service_response.error.present?

              service_response
            else
              fail NotImplementedError
            end
          end
        else
          case method
          when :get
            response = HTTPI.get(request)
            service_response = ExternalApi::Response.new(response)
            fail service_response.error if service_response.error.present?

            service_response
          else
            fail NotImplementedError
          end
        end
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
        key_phrases = get_key_phrases(ocr_data, stub_response: stub_response)
        filter_key_phrases_by_score(key_phrases)
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end

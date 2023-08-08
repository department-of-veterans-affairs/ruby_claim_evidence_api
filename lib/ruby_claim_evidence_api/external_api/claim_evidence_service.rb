# frozen_string_literal: true

require 'pry'
require 'httpi'
require 'active_support/all'
require 'ruby_claim_evidence_api/external_api/response'

module ExternalApi
  class ClaimEvidenceService
    JWT_TOKEN = ENV['CLAIM_EVIDENCE_JWT_TOKEN']
    BASE_URL = ENV['CLAIM_EVIDENCE_API_URL']
    CERT_FILE_LOCATION = ENV['SSL_CERT_FILE']
    SERVER = '/api/v1/rest'
    DOCUMENT_TYPES_ENDPOINT = '/documenttypes'
    HEADERS = {
      "Content-Type": 'application/json', Accept: 'application/json'
    }.freeze

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
        url = URI::DEFAULT_PARSER.escape(BASE_URL + SERVER + endpoint)
        request = HTTPI::Request.new(url)
        request.query = query
        request.open_timeout = 60
        request.read_timeout = 60
        request.body = body.to_json unless body.nil?
        request.auth.ssl.ssl_version  = :TLSv1_2
        request.auth.ssl.ca_cert_file = CERT_FILE_LOCATION
        request.headers = headers.merge(Authorization: "Bearer " + JWT_TOKEN)

        sleep 1
        # MetricsService.record("api.notifications.claim.evidence #{method.to_s.upcase} request to #{url}",
        #                       service: :claim_evidence,
        #                       name: endpoint) do
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
      # end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end

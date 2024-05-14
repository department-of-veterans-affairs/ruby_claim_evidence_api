# frozen_string_literal: true

require "ruby_claim_evidence_api/external_api/response"
require "faraday"
require "faraday/multipart"
require 'aws-sdk'
module Fakes
  class ClaimEvidenceService
    JWT_TOKEN = ENV["CLAIM_EVIDENCE_JWT_TOKEN"]
    BASE_URL = ENV["CLAIM_EVIDENCE_API_URL"]
    SERVER = "/api/v1/rest"
    DOCUMENT_TYPES_ENDPOINT = "/documenttypes"
    # this must start with http://
    HTTP_PROXY = ENV["DEVVPN_PROXY"]
    CERT_LOCATION = ENV["SSL_CERT_FILE"]
    KEY_LOCATION = ENV["CLAIM_EVIDENCE_KEY_FILE"]
    CERT_PASSWORD = ENV["CLAIM_EVIDENCE_CERT_PASSPHRASE"]
    HEADERS = {
      "Content-Type": "application/json",
      "Accept": "*/*"
    }.freeze
    CREDENTIALS = Aws::Credentials.new(
      ENV["AWS_ACCESS_KEY_ID"],
      ENV["AWS_SECRET_ACCESS_KEY"]
    )
    REGION = ENV["AWS_DEFAULT_REGION"]
    AWS_COMPREHEND_SCORE = ENV["AWS_COMPREHEND_SCORE"]

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
          headers: HEADERS.merge("Content-Type": "application/x-www-form-urlencoded"),
          endpoint: "/files/#{doc_uuid}/data/ocr",
          method: :get
        }
      end

      def upload_document_request(file, vet_file_number, doc_info)
        body = {}
        body[:file] = Faraday::Multipart::FilePart.new(file, "application/pdf")
        body[:payload] = Faraday::Multipart::ParamPart.new(doc_info, "application/json")
        {
          headers: HEADERS.merge(
            "Content-Type": "multipart/form-data",
            "X-Folder-URI": "VETERAN:FILENUMBER:#{vet_file_number}"
          ),
          endpoint: "/files",
          method: :post,
          body: body
        }
      end

      def document_types
        response = if HTTP_PROXY
                     use_faraday(document_types_request)
                   else
                     JSON.parse(IO.binread(File.join(Rails.root, "lib", "data", "DOCUMENT_TYPES.json")))
                   end

        if HTTP_PROXY
          response.body["documentTypes"]
        else
          response["documentTypes"]
        end
      end

      def alt_document_types
        response = if HTTP_PROXY
                     use_faraday(document_types_request)
                   else
                     JSON.parse(IO.binread(File.join(Rails.root, "lib", "data", "DOCUMENT_TYPES.json")))
                   end

        if HTTP_PROXY
          response.body["alternativeDocumentTypes"]
        else
          response["alternativeDocumentTypes"]
        end
      end

      def get_ocr_document(doc_uuid)
        response = if HTTP_PROXY
                     use_faraday(ocr_document_request(doc_uuid))
                   else
                     JSON.parse(IO.binread(File.join(Rails.root, "lib", "data", "OCR_DOCUMENT.json")))
                   end

        if HTTP_PROXY
          response.body["currentVersion"]["file"]["text"]
        else
          response["currentVersion"]["file"]["text"]
        end
      end

      def upload_document(file, vet_file_number, doc_info)
        use_faraday(upload_document_request(file, vet_file_number, doc_info)).body
      end

      def send_ce_api_request(endpoint:, query: {}, headers: {}, method: :get, body: nil)
        use_faraday(endpoint: endpoint, query: query, headers: headers, method: method, body: body)
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def use_faraday(endpoint:, query: {}, headers: {}, method: :get, body: nil)
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
          headers: headers.merge(Authorization: "Bearer #{JWT_TOKEN}"),
          proxy: HTTP_PROXY,
          ssl: {
            client_cert: client_cert,
            client_key: client_key,
            verify: false
          }
        ) do |c|
          c.request :multipart
          c.response :json
          c.adapter Faraday.default_adapter
          c.options.timeout = 120
          c.options.open_timeout = 120
        end

        sleep 1
        if Object.const_defined?('MetricsService')
          MetricsService.record("api.fakes.claim.evidence #{method.to_s.upcase} request to #{url}",
                                service: :claim_evidence,
                                name: endpoint) do
            handle_faraday_responses(
              conn: conn,
              method: method,
              endpoint: endpoint,
              body: body,
              query: query
            )
          end
        else
          handle_faraday_responses(
            conn: conn,
            method: method,
            endpoint: endpoint,
            body: body,
            query: query
          )
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

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
          language_code: "en"
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

      private

      def handle_faraday_responses(conn:, method:, endpoint:, query:, body:)
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
  end
end

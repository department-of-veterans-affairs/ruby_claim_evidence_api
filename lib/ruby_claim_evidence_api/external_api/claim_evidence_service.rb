# frozen_string_literal: true

require 'pry'
require 'httpi'
require 'active_support/all'
require 'ruby_claim_evidence_api/external_api/response'
# require 'aws-sdk'
require 'base64'

module ExternalApi
  # Establishes connection between Claims Evidence API, AWS, and Caseflow
  # Handles HTTP Requests, Errors, and business logic to Claims Evidence API

  # rubocop:disable Metrics/ClassLength
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

    FILES_CONTENT_PATH = '/files/:uuid/content'
    FOLDERS_FILES_SEARCH_PATH = '/folders/files:search'

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

      def upload_document_request(file_path, vet_file_number, doc_info)
        request = set_upload_document_form_data_for_request(
          request: Net::HTTP::Post.new(file_upload_uri),
          payload: doc_info,
          file_path: file_path
        )

        jwt_token = generate_jwt_token
        request['Authorization'] = "Bearer #{jwt_token}"
        request['X-Folder-URI'] = "VETERAN:FILENUMBER:#{vet_file_number}"

        request
      end

      def update_document_request(veteran_file_number:, file_uuid:, file_update_payload:)
        request = set_upload_document_form_data_for_request(
          request: Net::HTTP::Post.new(file_update_uri(file_uuid)),
          payload: {
            providerData: {
              contentSource: file_update_payload.file_content_source,
              documentTypeId: file_update_payload.document_type_id,
              dateVaReceivedDocument: file_update_payload.date_va_received_document,
              subject: file_update_payload.subject
            }
          },
          file_path: file_update_payload.file_content_path
        )

        request['Authorization'] = "Bearer #{generate_jwt_token}"
        request['X-Folder-URI'] = "VETERAN:FILENUMBER:#{veteran_file_number}"

        request
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

      def upload_document(file, vet_file_number, doc_info)
        send_multipart_post_request(upload_document_request(file, vet_file_number, doc_info)).body
      end

      def update_document(veteran_file_number:, file_uuid:, file_update_payload:)
        send_multipart_post_request(
          update_document_request(
            veteran_file_number: veteran_file_number,
            file_uuid: file_uuid,
            file_update_payload: file_update_payload
          )
        ).body
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
      def send_multipart_post_request(request)
        # Create Net::HTTP and configure
        http = Net::HTTP.new(request.uri.host, request.uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER

        http.ssl_version = :TLSv1_2
        http.ca_file = CERT_FILE_LOCATION
        http.cert = OpenSSL::X509::Certificate.new(File.read(ENV['BGS_CERT_LOCATION']))
        http.key = OpenSSL::PKey::RSA.new(File.read(ENV['BGS_KEY_LOCATION']))

        # Send Request
        if Object.const_defined?('MetricsService')
          MetricsService.record("api.claim.evidence POST request to '#{BASE_URL}#{SERVER}/files'",
                                service: :claim_evidence,
                                name: '/files') do
            handle_http_response(http, request)
          end
        else
          handle_http_response(http, request)
        end
      end

      # rubocop:disable Metrics/PerceivedComplexity
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
              response = HTTPI.get(request)
              service_response = ExternalApi::Response.new(response, request)
              fail service_response.error if service_response.error.present?

              service_response
            when :post
              response = HTTPI.post(request)
              service_response = ExternalApi::Response.new(response, request)
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
            service_response = ExternalApi::Response.new(response, request)
            fail service_response.error if service_response.error.present?

            service_response
          when :post
            response = HTTPI.post(request)
            service_response = ExternalApi::Response.new(response, request)
            fail service_response.error if service_response.error.present?

            service_response
          else
            fail NotImplementedError
          end
        end
      end
      # rubocop:enable Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/CyclomaticComplexity


      # REGION = ENV['AWS_REGION']
      # AWS_COMPREHEND_SCORE = ENV['AWS_COMPREHEND_SCORE']

      # def aws_client
      #   @aws_client ||= Aws::Comprehend::Client.new(
      #     region: REGION
      #   )
      # end

      # def aws_stub_client
      #   @aws_stub_client ||= Aws::Comprehend::Client.new(
      #     region: REGION,
      #     stub_responses: true
      #   )
      # end

      # def get_key_phrases(ocr_data, stub_response: false)
      #   key_phrase_parameters = {
      #     text: ocr_data,
      #     language_code: 'en'
      #   }
      #   if stub_response == true
      #     aws_stub_client.detect_key_phrases(key_phrase_parameters).key_phrases
      #   else
      #     aws_client.detect_key_phrases(key_phrase_parameters).key_phrases
      #   end
      # end

      # def filter_key_phrases_by_score(key_phrases)
      #   key_phrases.filter_map do |key_phrase|
      #     key_phrase[:text] if !key_phrase[:score].nil? && key_phrase[:score] >= AWS_COMPREHEND_SCORE.to_f
      #   end
      # end

      # def get_key_phrases_from_document(doc_uuid, stub_response: false)
      #   ocr_data = get_ocr_document(doc_uuid)

      #   return unless ocr_data.present?

      #   key_phrases = get_key_phrases(ocr_data, stub_response: stub_response)
      #   filter_key_phrases_by_score(key_phrases)
      # end

      private

      def handle_http_response(http, request)
        http.start do |https|
          response = https.request(request)
          service_response = ExternalApi::Response.new(response, request, uses_net_http: true)
          fail service_response.error if service_response.error.present?

          return service_response
        end
      end

      def set_upload_document_form_data_for_request(request:, payload:, file_path:)
        file_content = File.binread(file_path)
        form_data = []
        form_data << ['file', file_content, { filename: File.basename(file_path), content_type: 'application/pdf' }]
        form_data << ['payload', payload.to_json]
        request.set_form form_data, 'multipart/form-data'
        request
      end

      def file_upload_uri
        @file_upload_uri = URI("#{BASE_URL}#{SERVER}/files")
      end

      def file_update_uri(file_uuid)
        @file_update_uri = URI("#{BASE_URL}#{SERVER}/files/#{file_uuid}")
      end

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
          applicationID: TOKEN_ISSUER,
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
  end
  # rubocop:enable Metrics/ClassLength, Metrics/MethodLength
end

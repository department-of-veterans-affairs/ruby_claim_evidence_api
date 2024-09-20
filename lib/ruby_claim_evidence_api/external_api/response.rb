# frozen_string_literal: true

require 'faraday'
require 'active_support/all'
require 'ruby_claim_evidence_api/error'

module ExternalApi
  # Response Class for error handling
  class Response
    attr_reader :resp, :code

    def initialize(resp, request, uses_net_http: false)
      @resp = resp
      @uses_net_http = uses_net_http
      @code = @resp.try(:code).to_i || @resp.try(:status)
      @request = request
    end

    # Wrapper method to check for errors
    def error
      check_for_error
    end

    # Checks if there is no error
    def success?
      resp.try(:success?) || code == 200
    end

    # Parses response body to an object
    def body
      if resp.is_a?(Faraday::Response)
        resp.body
      else
        @body ||=
          begin
            JSON.parse(resp.body)
          rescue JSON::ParserError
            {}
          end
      end
    end

    def to_json(custom_message: nil)
      {
        custom_message: custom_message,
        error: error_message,
        body: body
      }
    end

    private

    # Error codes and their associated error
    ERROR_LOOKUP = {
      400 => ClaimEvidenceApi::Error::ClaimEvidenceBadRequestError,
      401 => ClaimEvidenceApi::Error::ClaimEvidenceUnauthorizedError,
      403 => ClaimEvidenceApi::Error::ClaimEvidenceForbiddenError,
      404 => ClaimEvidenceApi::Error::ClaimEvidenceNotFoundError,
      415 => ClaimEvidenceApi::Error::ClaimEvidenceMediaTypeError,
      429 => ClaimEvidenceApi::Error::ClaimEvidenceRateLimitError,
      500 => ClaimEvidenceApi::Error::ClaimEvidenceInternalServerError,
      501 => ClaimEvidenceApi::Error::ClaimEvidenceNotImplementedError,
      503 => ClaimEvidenceApi::Error::ClaimEvidenceNotFoundError
    }.freeze

    # Checks for error and returns if found
    def check_for_error
      return if success?

      message = error_message
      if ERROR_LOOKUP.key? code
        ERROR_LOOKUP[code].new(code: code, message: message, request: @request)
      else
        ClaimEvidenceApi::Error::ClaimEvidenceApiError.new(code: code, message: message, request: @request)
      end
    end

    # Gets the error message from the response
    def error_message
      return 'No error message from ClaimEvidence' if body.nil? || body.empty?

      begin
        if @uses_net_http == true
          body['message']
        else
          # Possible error response shapes taken from Claim Evidence Swagger
          body['message'] || body['messages'] || body['errors'][0]['message']
        end
      rescue StandardError => e
        "Encountered #{e} while attempting to access response body"
      end
    end
  end
end

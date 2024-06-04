# frozen_string_literal: true

require 'faraday'
require 'active_support/all'
require 'ruby_claim_evidence_api/error'

module ExternalApi
  # Response Class for error handling
  class Response
    attr_reader :resp, :code

    def initialize(resp, uses_net_http: false)
      @resp = resp
      @uses_net_http = uses_net_http
      @code = @resp.try(:code).to_i || @resp.try(:status)
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
        ERROR_LOOKUP[code].new(code: code, message: message)
      else
        ClaimEvidenceApi::Error::ClaimEvidenceApiError.new(code: code, message: message)
      end
    end

    # Gets the error message from the response
    def error_message
      return 'No error message from ClaimEvidence' if body.empty?

      if @uses_net_http == true
        body['message']
      else
        body['messages'] || body['errors'][0]['message']
      end
    end
  end
end

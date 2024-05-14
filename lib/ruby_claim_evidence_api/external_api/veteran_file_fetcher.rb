# frozen_string_literal: true

require 'httpi'
require 'ruby_claim_evidence_api/external_api/response'
require_relative '../helpers/string_parser'
require 'ruby_claim_evidence_api'

module ExternalApi
  # Fetches CE API documents for a given veteran
  class VeteranFileFetcher < RubyClaimEvidenceApi
    include StringParser
    def get_document_content(doc_series_id:)
      doc_series_id = parse_document_id(doc_series_id)
      response = api_client.send_ce_api_request(get_document_content_request(doc_series_id))
      # Returning this value as the api call returns a byte string and not a JSON body
      response.resp.body
    end

    private

    def get_document_content_request(doc_series_id)
      {
        headers: basic_header,
        endpoint: "/files/#{doc_series_id}/content",
        method: :get
      }
    end

    def basic_header
      {
        "Content-Type": 'application/json',
        "Accept": '*/*'
      }.freeze
    end
  end
end

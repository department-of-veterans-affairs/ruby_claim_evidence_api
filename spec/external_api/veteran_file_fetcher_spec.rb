# frozen_string_literal: true

require 'ruby_claim_evidence_api/api_base'
require 'ruby_claim_evidence_api/external_api/claim_evidence_service'
require 'ruby_claim_evidence_api/external_api/response'
require 'ruby_claim_evidence_api/external_api/veteran_file_fetcher'
require './spec/external_api/spec_helper'

describe ExternalApi::VeteranFileFetcher do
  subject(:described) { described_class.new(use_canned_api_responses: false) }

  let(:mock_api_response) do
    instance_double(
      ExternalApi::Response,
      body: { page: { totalResults: 0, totalPages: 1, currentPage: 1 } }.with_indifferent_access
    )
  end

  describe '#fetch_veteran_file_list' do
    it 'calls the API endpoint' do
      expect(ExternalApi::ClaimEvidenceService).to receive(:send_ce_api_request)
        .with(
          endpoint: '/folders/files:search',
          query: {},
          headers: {
            "Content-Type": 'application/json',
            "Accept": '*/*',
            "X-Folder-URI": 'VETERAN:FILENUMBER:123456789'
          },
          method: :post,
          body: {
            "pageRequest": {
              "resultsPerPage": 20,
              "page": 1
            },
            "filters": {}
          }
        ).and_return(mock_api_response)

      described.fetch_veteran_file_list(veteran_file_number: '123456789')
    end
  end
end

# frozen_string_literal: true

require 'ruby_claim_evidence_api/external_api/claim_evidence_service'
require 'ruby_claim_evidence_api/external_api/veteran_file_fetcher'
require './spec/external_api/spec_helper'

describe ExternalApi::VeteranFileFetcher do
  subject(:described) { described_class.new }

  let(:mock_ce_service) { class_double('ExternalApi::ClaimEvidenceService').as_stubbed_const }

  describe '.fetch_veteran_file_list' do
    it 'successfully calls the endpoint' do
      expect(mock_ce_service).to receive(:send_ce_api_request).with(
        endpoint: '/folders/files:search',
        query: {},
        headers: { 'X-Folder-URI': 'VETERAN:FILENUMBER:123456789' },
        method: :post,
        body: nil
      )

      described.fetch_veteran_file_list(veteran_file_number: '123456789')
    end
  end
end

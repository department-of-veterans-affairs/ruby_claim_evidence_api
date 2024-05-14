# frozen_string_literal: true

require './spec/external_api/spec_helper'
require 'httpi'
require 'ruby_claim_evidence_api/external_api/claim_evidence_service'
require 'ruby_claim_evidence_api/external_api/response'
require 'ruby_claim_evidence_api/external_api/veteran_file_fetcher'

describe ExternalApi::VeteranFileFetcher do
  subject(:described) { described_class.new(use_canned_api_responses: false) }
  subject(:described_canned_responses) { described_class.new(use_canned_api_responses: true) }

  let(:mock_ce_service) { class_double('ExternalApi::ClaimEvidenceService').as_stubbed_const }

  let(:document_content_response) { ExternalApi::Response.new(HTTPI::Response.new(200, {}, 'PDF% abc123')) }

  describe '.get_document_content' do
    it 'calls the ClaimEvidenceService and returns a byte string' do
      expect(mock_ce_service).to receive(:send_ce_api_request).once.and_return(document_content_response)

      response = described.get_document_content(doc_series_id: '123456789')
      expect(response).to eq 'PDF% abc123'
    end
  end
end

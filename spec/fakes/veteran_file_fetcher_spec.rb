# frozen_string_literal: true

require './spec/external_api/spec_helper'
require 'json'
require 'ruby_claim_evidence_api/fakes/claim_evidence_service'
require 'ruby_claim_evidence_api/fakes/veteran_file_fetcher'

describe Fakes::VeteranFileFetcher do
  subject(:described) { described_class.new }

  let(:mock_fake_ce_service) { class_double('Fakes::ClaimEvidenceService').as_stubbed_const }

  let(:file_folders_search_single_page) do
    json_obj = File.read(
      File.join(
        Gem::Specification.find_by_name('ruby_claim_evidence_api').gem_dir,
        'spec/support/api_responses/file_folders_search_single_page.json'
      )
    )

    ExternalApi::Response.new(HTTPI::Response.new(200, {}, json_obj))
  end

  let(:document_content_response) { ExternalApi::Response.new(HTTPI::Response.new(200, {}, 'PDF% EwyxLoOCsds#4W23PL')) }

  describe '.fetch_veteran_file_list' do
    it 'calls the faked ClaimEvidenceService' do
      expect(mock_fake_ce_service).to receive(:send_ce_api_request).once.and_return(file_folders_search_single_page)

      described.fetch_veteran_file_list(veteran_file_number: '123456789')
    end
  end

  describe '.get_document_content' do
    it 'calls the faked ClaimEvidenceService' do
      expect(mock_fake_ce_service).to receive(:send_ce_api_request).once.and_return(document_content_response)

      described.get_document_content(doc_series_id: '123456789')
    end
  end
end

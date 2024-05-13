# frozen_string_literal: true

require './spec/external_api/spec_helper'
require 'httpi'
require 'ruby_claim_evidence_api/external_api/claim_evidence_service'
require 'ruby_claim_evidence_api/external_api/response'
require 'ruby_claim_evidence_api/external_api/veteran_file_fetcher'

describe ExternalApi::VeteranFileFetcher do
  subject(:described) { described_class.new }

  let(:mock_ce_service) { class_double('ExternalApi::ClaimEvidenceService').as_stubbed_const }

  let(:file_folders_search_single_page) do
    json_obj = File.read(
      File.join(
        Gem::Specification.find_by_name('ruby_claim_evidence_api').gem_dir,
        'spec/support/api_responses/file_folders_search_single_page.json'
      )
    )

    ExternalApi::Response.new(HTTPI::Response.new(200, {}, json_obj))
  end

  let(:file_folders_search1) do
    json_obj = File.read(
      File.join(
        Gem::Specification.find_by_name('ruby_claim_evidence_api').gem_dir,
        'spec/support/api_responses/file_folders_search_1.json'
      )
    )

    ExternalApi::Response.new(HTTPI::Response.new(200, {}, json_obj))
  end

  let(:file_folders_search2) do
    json_obj = File.read(
      File.join(
        Gem::Specification.find_by_name('ruby_claim_evidence_api').gem_dir,
        'spec/support/api_responses/file_folders_search_2.json'
      )
    )

    ExternalApi::Response.new(HTTPI::Response.new(200, {}, json_obj))
  end

  let(:document_content_response) { ExternalApi::Response.new(HTTPI::Response.new(200, {}, 'PDF% abc123')) }

  describe '.fetch_veteran_file_list' do
    context 'with a single result page' do
      it 'successfully calls the API' do
        vet_file_number = '123456789'

        expect(mock_ce_service).to receive(:send_ce_api_request).once.and_return(file_folders_search_single_page)

        response = described.fetch_veteran_file_list(veteran_file_number: vet_file_number)
        expect(response.body['files'].length).to eq 1
        expect(response.body['files'][0]['uuid']).to eq '33333333-3333-3333-3333-333333333333'
      end
    end

    context 'with multiple result pages' do
      it 'retrieves all of the available results' do
        vet_file_number = '123456789'

        expect(mock_ce_service).to receive(:send_ce_api_request).once.and_return(file_folders_search1)
        expect(mock_ce_service).to receive(:send_ce_api_request).once.and_return(file_folders_search2)

        response = described.fetch_veteran_file_list(veteran_file_number: vet_file_number)
        expect(response.body['files'].length).to eq 2
        expect(response.body['files'][0]['uuid']).to eq '11111111-1111-1111-1111-111111111111'
        expect(response.body['files'][1]['uuid']).to eq '22222222-2222-2222-2222-222222222222'
      end
    end
  end

  describe '.get_document_content' do
    it 'calls the ClaimEvidenceService adn returns a byte string' do
      expect(mock_ce_service).to receive(:send_ce_api_request).once.and_return(document_content_response)

      response = described.get_document_content(doc_series_id: '123456789')
      expect(response).to eq 'PDF% abc123'
    end
  end
end

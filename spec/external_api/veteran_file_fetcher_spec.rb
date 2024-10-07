# frozen_string_literal: true

require 'ruby_claim_evidence_api/api_base'
require 'ruby_claim_evidence_api/external_api/claim_evidence_service'
require 'ruby_claim_evidence_api/external_api/response'
require 'ruby_claim_evidence_api/external_api/veteran_file_fetcher'
require 'ruby_claim_evidence_api/models/claim_evidence_request'
require './spec/external_api/spec_helper'

describe ExternalApi::VeteranFileFetcher do
  subject(:described) { described_class.new(use_canned_api_responses: false) }

  let(:mock_json_response) do
    instance_double(
      ExternalApi::Response,
      body: { page: { totalResults: 0, totalPages: 1, currentPage: 1 } }.with_indifferent_access
    )
  end

  let(:mock_doc_content_response) do
    instance_double(
      ExternalApi::Response,
      resp: mock_json_response
    )
  end

  let(:claim_evidence_request) do
    ClaimEvidenceRequest.new(
      user_css_id: 'USER_999',
      station_id: 123
    )
  end

  let(:mock_claim_evidence_service) { instance_double(ExternalApi::ClaimEvidenceService) }

  before do
    allow(ExternalApi::ClaimEvidenceService).to receive(:new).with(claim_evidence_request: claim_evidence_request)
                                                             .and_return(mock_claim_evidence_service)
  end

  describe '#fetch_veteran_file_list' do
    it 'sucessfully calls the API endpoint' do
      expect(mock_claim_evidence_service).to receive(:send_ce_api_request)
        .with(
          endpoint: '/folders/files:search',
          query: {},
          headers: {
            'Content-Type': 'application/json',
            'Accept': '*/*',
            'X-Folder-URI': 'VETERAN:FILENUMBER:123456789'
          },
          method: :post,
          body: {
            'pageRequest': {
              'resultsPerPage': 20,
              'page': 1
            },
            'filters': {}
          }
        ).and_return(mock_json_response)

      described.fetch_veteran_file_list(
        veteran_file_number: '123456789',
        claim_evidence_request: claim_evidence_request
      )
    end
  end

  describe '#fetch_veteran_file_list_by_date_range' do
    let(:begin_date_range) { 2.weeks.ago }
    let(:end_date_range) { 1.week.ago }

    it 'sucessfully calls the API endpoint' do
      expect(mock_claim_evidence_service).to receive(:send_ce_api_request)
        .with(
          endpoint: '/folders/files:search',
          query: {},
          headers: {
            'Content-Type': 'application/json',
            'Accept': '*/*',
            'X-Folder-URI': 'VETERAN:FILENUMBER:123456789'
          },
          method: :post,
          body: {
            'pageRequest': {
              'resultsPerPage': 20,
              'page': 1
            },
            'filters': {
              'systemData.uploadedDateTime': {
                'evaluationType': 'BETWEEN',
                'value': [begin_date_range, end_date_range]
              }
            }
          }
        ).and_return(mock_json_response)

      described.fetch_veteran_file_list_by_date_range(
        veteran_file_number: '123456789',
        claim_evidence_request: claim_evidence_request,
        begin_date_range: begin_date_range,
        end_date_range: end_date_range
      )
    end
  end

  describe '#get_document_content' do
    it 'sucessfully calls the API endpoint' do
      expect(mock_claim_evidence_service).to receive(:send_ce_api_request)
        .with(
          endpoint: '/files/123456789/content',
          headers: {
            'Content-Type': 'application/json',
            'Accept': '*/*'
          },
          method: :get
        ).and_return(mock_doc_content_response)

      described.get_document_content(
        doc_series_id: '123456789',
        claim_evidence_request: claim_evidence_request
      )
    end
  end
end

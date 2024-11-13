# frozen_string_literal: true

require 'ruby_claim_evidence_api/api_base'
require 'ruby_claim_evidence_api/external_api/claim_evidence_service'
require 'ruby_claim_evidence_api/external_api/response'
require 'ruby_claim_evidence_api/external_api/veteran_file_updater'
require 'ruby_claim_evidence_api/models/claim_evidence_file_update_payload'
require 'ruby_claim_evidence_api/models/claim_evidence_request'
require './spec/external_api/spec_helper'

describe ExternalApi::VeteranFileUpdater do
  subject(:described) { described_class.new(use_canned_api_responses: false) }

  let(:mock_api_response) { instance_double(ExternalApi::Response) }
  let(:mock_claim_evidence_service) { instance_double(ExternalApi::ClaimEvidenceService) }

  let(:claim_evidence_request) do
    ClaimEvidenceRequest.new(
      user_css_id: 'USER_999',
      station_id: 123
    )
  end

  before do
    allow(ExternalApi::ClaimEvidenceService).to receive(:new).with(claim_evidence_request: claim_evidence_request)
                                                             .and_return(mock_claim_evidence_service)
  end

  describe '#update_veteran_file' do
    it 'calls the API endpoint' do
      expect(mock_claim_evidence_service).to receive(:update_document)
        .with(
          veteran_file_number: '123456789',
          file_uuid: '0003E65D-0000-C118-A964-CA1AEC2925E6',
          file_update_payload: instance_of(ClaimEvidenceFileUpdatePayload)
        ).and_return(mock_api_response)

      described.update_veteran_file(
        veteran_file_number: '123456789',
        claim_evidence_request: claim_evidence_request,
        file_uuid: '0003E65D-0000-C118-A964-CA1AEC2925E6',
        file_update_payload: ClaimEvidenceFileUpdatePayload.new
      )
    end
  end
end

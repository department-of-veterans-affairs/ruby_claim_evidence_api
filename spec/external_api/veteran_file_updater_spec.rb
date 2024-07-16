# frozen_string_literal: true

require 'ruby_claim_evidence_api/api_base'
require 'ruby_claim_evidence_api/external_api/claim_evidence_service'
require 'ruby_claim_evidence_api/external_api/response'
require 'ruby_claim_evidence_api/external_api/veteran_file_updater'
require 'ruby_claim_evidence_api/models/file_update_request'
require './spec/external_api/spec_helper'

describe ExternalApi::VeteranFileUpdater do
  subject(:described) { described_class.new(use_canned_api_responses: false) }

  let(:mock_api_response) { instance_double(ExternalApi::Response) }

  describe '#update_veteran_file' do
    it 'calls the API endpoint' do
      expect(ExternalApi::ClaimEvidenceService).to receive(:send_ce_api_request)
        .with(
          endpoint: '/files/0003E65D-0000-C118-A964-CA1AEC2925E6',
          query: {},
          headers: {
            "Content-Type": 'application/json',
            "Accept": '*/*',
            "X-Folder-URI": 'VETERAN:FILENUMBER:123456789'
          },
          method: :post,
          body:{
            payload: {
              providerData: {
                contentSource: '',
                documentTypeId: '',
                dateVaReceivedDocument: ''
              }
            },
            file: ''
          }
        ).and_return(mock_api_response)

      file_update_request = FileUpdateRequest.new

      described.update_veteran_file(
        veteran_file_number: '123456789',
        file_uuid: '0003E65D-0000-C118-A964-CA1AEC2925E6',
        file_update_request: file_update_request
      )
    end
  end
end

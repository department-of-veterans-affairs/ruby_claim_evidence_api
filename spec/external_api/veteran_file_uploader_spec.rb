# frozen_string_literal: true

require 'ruby_claim_evidence_api/api_base'
require 'ruby_claim_evidence_api/external_api/claim_evidence_service'
require 'ruby_claim_evidence_api/external_api/response'
require 'ruby_claim_evidence_api/external_api/veteran_file_uploader'
require 'ruby_claim_evidence_api/models/claim_evidence_file_upload_payload'
require 'ruby_claim_evidence_api/models/claim_evidence_request'
require './spec/external_api/spec_helper'

describe ExternalApi::VeteranFileUploader do
  subject(:veteran_file_uploader) { described_class.new(use_canned_api_responses: false) }

  let(:mock_api_response) { instance_double(ExternalApi::Response) }
  let(:doc_info) do
    ClaimEvidenceFileUploadPayload.new(
      content_name: 'test.pdf',
      content_source: 'BVA',
      date_va_received_document: '2024-07-26',
      document_type_id: 1757,
      subject: 'Notifications',
      new_mail: true
    )
  end
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

  describe '#upload_veteran_file' do
    it 'calls the API endpoint with the correct parameters' do
      expected_payload = {
        contentName: 'test.pdf',
        providerData: {
          contentSource: 'BVA',
          documentTypeId: 1757,
          dateVaReceivedDocument: '2024-07-26',
          subject: 'Notifications',
          newMail: true
        }
      }

      expect(mock_claim_evidence_service).to receive(:upload_document)
        .with(
          'path/to/test.pdf',
          '123456789',
          expected_payload
        ).and_return(mock_api_response)

      veteran_file_uploader.upload_veteran_file(
        file_path: 'path/to/test.pdf',
        claim_evidence_request: claim_evidence_request,
        veteran_file_number: '123456789',
        doc_info: doc_info
      )
    end
  end
end

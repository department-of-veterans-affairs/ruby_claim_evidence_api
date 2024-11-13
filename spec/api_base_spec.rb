# frozen_string_literal: true

require 'ruby_claim_evidence_api/api_base'
require 'ruby_claim_evidence_api/models/claim_evidence_request'
require './spec/external_api/spec_helper'

describe ApiBase do
  let(:claim_evidence_request) do
    ClaimEvidenceRequest.new(
      user_css_id: 'USER_999',
      station_id: 123
    )
  end

  context 'when canned API responses are used' do
    let(:described) { described_class.new(use_canned_api_responses: true) }

    it 'uses a mock API client' do
      expect(described.send(:api_client, { claim_evidence_request: claim_evidence_request })).to be_an_instance_of MockApiClient
    end
  end

  context 'when canned API responses are NOT used' do
    let(:described) { described_class.new(use_canned_api_responses: false) }

    it 'uses the actual API client' do
      expect(
        described.send(:api_client, { claim_evidence_request: claim_evidence_request })
      ).to be_an_instance_of ExternalApi::ClaimEvidenceService
    end
  end
end

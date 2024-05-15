# frozen_string_literal: true

require 'ruby_claim_evidence_api/ruby_claim_evidence_api'
require './spec/external_api/spec_helper'

describe RubyClaimEvidenceApi do
  context 'when canned API responses are used' do
    let(:described) { described_class.new(use_canned_api_responses: true) }

    it 'uses a mock API client' do
      expect(described.send(:api_client)).to be_an_instance_of MockApiClient
    end
  end

  context 'when canned API responses are NOT used' do
    let(:described) { described_class.new(use_canned_api_responses: false) }

    it 'uses the actual API client' do
      expect(described.send(:api_client).new).to be_a ExternalApi::ClaimEvidenceService
    end
  end
end

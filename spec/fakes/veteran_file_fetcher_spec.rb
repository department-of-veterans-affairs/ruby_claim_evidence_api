# frozen_string_literal: true

require 'ruby_claim_evidence_api/fakes/claim_evidence_service'
require 'ruby_claim_evidence_api/fakes/veteran_file_fetcher'
require './spec/external_api/spec_helper'

describe Fakes::VeteranFileFetcher do
  subject(:described) { described_class.new }

  let(:mock_fake_ce_service) { class_double('Fakes::ClaimEvidenceService').as_stubbed_const }

  describe '.fetch_veteran_file_list' do
    it 'calls the faked ClaimEvidenceService' do
      vet_file_number = '123456789'

      expect(mock_fake_ce_service).to receive(:send_ce_api_request).with(
        endpoint: '/folders/files:search',
        query: {},
        headers: { 'X-Folder-URI': "VETERAN:FILENUMBER:#{vet_file_number}" },
        method: :post,
        body: nil
      )

      described.fetch_veteran_file_list(veteran_file_number: vet_file_number)
    end
  end
end

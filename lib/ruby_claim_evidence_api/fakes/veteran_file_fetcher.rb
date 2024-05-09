# frozen_string_literal: true

require 'ruby_claim_evidence_api/external_api/veteran_file_fetcher'

module Fakes
  # Fake wrapper for the VeteranFileFetcher class
  class VeteranFileFetcher < ExternalApi::VeteranFileFetcher
    private

    def claim_evidence_service
      Fakes::ClaimEvidenceService
    end
  end
end

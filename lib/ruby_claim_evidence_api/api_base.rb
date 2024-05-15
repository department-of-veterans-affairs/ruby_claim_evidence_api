# frozen_string_literal: true

require 'ruby_claim_evidence_api/external_api/claim_evidence_service'
require 'ruby_claim_evidence_api/fakes/mock_api_client'

class ApiBase
  def initialize(use_canned_api_responses:)
    self.use_canned_api_responses = use_canned_api_responses
  end

  private

  attr_accessor :use_canned_api_responses

  def api_client
    return @api_client unless @api_client.nil?

    if use_canned_api_responses
      @api_client = MockApiClient.new
    else
      @api_client = ExternalApi::ClaimEvidenceService
    end

    @api_client
  end
end

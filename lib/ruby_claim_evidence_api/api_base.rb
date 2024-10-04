# frozen_string_literal: true

require 'ruby_claim_evidence_api/external_api/claim_evidence_service'
require 'ruby_claim_evidence_api/fakes/mock_api_client'

# Allows VeteranFileFetcher configuration
class ApiBase
  def initialize(use_canned_api_responses:, logger: Logger.new($stdout))
    self.use_canned_api_responses = use_canned_api_responses
    self.logger = logger
  end

  private

  attr_accessor :use_canned_api_responses, :logger

  def api_client
    return @api_client unless @api_client.nil?

    @api_client = if use_canned_api_responses
                    MockApiClient.new
                  else
                    ExternalApi::ClaimEvidenceService.new
                  end

    @api_client
  end

  def x_folder_uri_header(veteran_file_number)
    {
      "Content-Type": 'application/json',
      "Accept": '*/*',
      "X-Folder-URI": "VETERAN:FILENUMBER:#{veteran_file_number}"
    }
  end
end

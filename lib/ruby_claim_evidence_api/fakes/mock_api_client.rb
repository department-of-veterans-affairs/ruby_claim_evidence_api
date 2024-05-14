# frozen_string_literal: true

require 'httpi'
require 'ruby_claim_evidence_api/external_api/response'
require 'ruby_claim_evidence_api/external_api/claim_evidence_service'

class MockApiClient
  def method_missing(m, *args, &block)
    mock_api_response(*args)
  end

  private

  def mock_api_response(*args)
    endpoint = args[0][:endpoint]

    case endpoint
    when /\/files\/[\w\d-]+\/content/
      files_content_response
    when ExternalApi::ClaimEvidenceService::FOLDERS_FILES_SEARCH_PATH
      files_folders_search_response
    else
      not_found_response
    end
  end

  def files_folders_search_response
    ExternalApi::Response.new(
      HTTPI::Response.new(200, {}, { status: 'ok' })
    )
  end

  def files_content_response
    ExternalApi::Response.new(
      HTTPI::Response.new(200, {}, { status: 'ok' })
    )
  end

  def not_found_response
    ExternalApi::Response.new(
      HTTPI::Response.new(404, {}, { status: 'not found' })
    )
  end
end

# frozen_string_literal: true

require 'httpi'
require 'ruby_claim_evidence_api/external_api/response'
require 'ruby_claim_evidence_api/external_api/claim_evidence_service'

# Mocks API responses keyed off of API URI paths
class MockApiClient
  def respond_to_missing?(_method_name, _include_private = false); end

  def method_missing(_method, *args, &_block)
    mock_api_response(*args)
  end

  private

  def mock_api_response(*args)
    endpoint = args[0][:endpoint]

    case endpoint
    when %r{\/files\/[\w\d-]+\/content}
      files_content_response
    when %r{\/files\/[\w\d-]+}
      update_veteran_file_response
    when ExternalApi::ClaimEvidenceService::FOLDERS_FILES_SEARCH_PATH
      files_folders_search_response
    else
      not_found_response
    end
  end

  def files_content_response
    file_name = File.join(
      Gem::Specification.find_by_name('ruby_claim_evidence_api').gem_dir,
      'spec/support/get_document_content.pdf'
    )
    ExternalApi::Response.new(
      HTTPI::Response.new(200, {}, File.binread(file_name))
    )
  end

  def files_folders_search_response
    json_obj = File.read(
      File.join(
        Gem::Specification.find_by_name('ruby_claim_evidence_api').gem_dir,
        'spec/support/api_responses/file_folders_search_single_page.json'
      )
    )

    ExternalApi::Response.new(HTTPI::Response.new(200, {}, json_obj))
  end

  def update_veteran_file_response
    json_obj = File.read(
      File.join(
        Gem::Specification.find_by_name('ruby_claim_evidence_api').gem_dir,
        'spec/support/api_responses/update_veteran_file_response.json'
      )
    )

    ExternalApi::Response.new(HTTPI::Response.new(200, {}, json_obj))
  end

  def not_found_response
    ExternalApi::Response.new(
      HTTPI::Response.new(404, {}, { status: 'not found' })
    )
  end
end

# frozen_string_literal: true

require 'ruby_claim_evidence_api/api_base'

module ExternalApi
  # Updates documents in the CE API documents for a given veteran
  class VeteranFileUpdater < ApiBase
    def update_veteran_file(veteran_file_number:, file_uuid:, file_update_payload:)
      api_client.update_document(
        veteran_file_number: veteran_file_number,
        file_uuid: file_uuid,
        file_update_payload: file_update_payload
      )
    end
  end
end

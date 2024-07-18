# frozen_string_literal: true

require 'ruby_claim_evidence_api/api_base'

module ExternalApi
  # Updates documents in the CE API documents for a given veteran
  class VeteranFileUpdater < ApiBase
    def update_veteran_file(veteran_file_number:, file_uuid:, file_update_payload:)
      post_files_uuid(
        veteran_file_number: veteran_file_number,
        file_uuid: file_uuid,
        body: update_veteran_file_body(file_update_payload)
      )
    end

    private

    def post_files_uuid(veteran_file_number:, file_uuid:, query: {}, body: nil)
      api_client.send_ce_api_request(
        endpoint: "/files/#{file_uuid}",
        query: query,
        headers: x_folder_uri_header(veteran_file_number),
        method: :post,
        body: body
      )
    end

    def update_veteran_file_body(file_update_payload)
      {
        payload: {
          providerData: {
            contentSource: file_update_payload.file_content_source,
            documentTypeId: file_update_payload.document_type_id,
            dateVaReceivedDocument: file_update_payload.date_va_received_document
          }
        },
        file: file_update_payload.file_content
      }
    end
  end
end

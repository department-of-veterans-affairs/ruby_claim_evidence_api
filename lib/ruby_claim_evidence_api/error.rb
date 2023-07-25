# frozen_string_literal: true

module ClaimEvidenceApi
  module Error
    
    # VANotify Errors
    class VANotifyApiError < StandardError; end
    class ClaimEvidenceNotFoundErrorVANotifyNotFoundError < VANotifyApiError; end
    
    # ClaimEvidence Errors
    class ClaimEvidenceApiError < StandardError; end
    class ClaimEvidenceUnauthorizedError < ClaimEvidenceApiError; end
    class ClaimEvidenceForbiddenError < ClaimEvidenceApiError; end
    class ClaimEvidenceNotFoundError < ClaimEvidenceApiError; end
    class ClaimEvidenceInternalServerError < ClaimEvidenceApiError; end
    class ClaimEvidenceRateLimitError < ClaimEvidenceApiError; end
  
  end
end
  
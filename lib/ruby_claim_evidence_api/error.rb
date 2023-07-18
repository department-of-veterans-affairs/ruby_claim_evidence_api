# frozen_string_literal: true

module Caseflow::Error
    
    # VANotify Errors
    class ClaimEvidenceNotFoundErrorVANotifyNotFoundError < VANotifyApiError; end
    
    # ClaimEvidence Errors
    class ClaimEvidenceApiError < StandardError; end
    class ClaimEvidenceUnauthorizedError < ClaimEvidenceApiError; end
    class ClaimEvidenceForbiddenError < ClaimEvidenceApiError; end
    class ClaimEvidenceNotFoundError < ClaimEvidenceApiError; end
    class ClaimEvidenceInternalServerError < ClaimEvidenceApiError; end
    class ClaimEvidenceRateLimitError < ClaimEvidenceApiError; end
  
  end
  
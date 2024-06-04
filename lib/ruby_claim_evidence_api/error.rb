# frozen_string_literal: true

module ClaimEvidenceApi
  module Error

    # ClaimEvidence Errors
    class ClaimEvidenceApiError < StandardError; end
    class ClaimEvidenceUnauthorizedError < ClaimEvidenceApiError; end
    class ClaimEvidenceForbiddenError < ClaimEvidenceApiError; end
    class ClaimEvidenceNotFoundError < ClaimEvidenceApiError; end
    class ClaimEvidenceInternalServerError < ClaimEvidenceApiError; end
    class ClaimEvidenceRateLimitError < ClaimEvidenceApiError; end
    class ClaimEvidenceNotImplementedError < ClaimEvidenceApiError; end
    class ClaimEvidenceMediaTypeError < ClaimEvidenceApiError; end
    class ClaimEvidenceBadRequestError < ClaimEvidenceApiError; end
  end
end

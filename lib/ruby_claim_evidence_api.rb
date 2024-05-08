# frozen_string_literal: true

require 'pry'

# Configuration
require 'lib/ruby_claim_evidence_api/configuration'

# Services
require 'ruby_claim_evidence_api/external_api/claim_evidence_service'
require 'ruby_claim_evidence_api/external_api/veteran_file_fetcher'

# Fakes
require 'ruby_claim_evidence_api/fakes/claim_evidence_service'
require 'ruby_claim_evidence_api/fakes/veteran_file_fetcher'

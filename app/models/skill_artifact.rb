class SkillArtifact < ApplicationRecord
  ARTIFACT_TYPES = %w[mcp_tool_manifest].freeze

  belongs_to :skill_version

  validates :artifact_type, presence: true, inclusion: { in: ARTIFACT_TYPES }
  validates :checksum, presence: true
  validates :manifest, presence: true
end

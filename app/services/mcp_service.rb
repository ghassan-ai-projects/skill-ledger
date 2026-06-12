class McpService
  class Error < StandardError
    attr_reader :code

    def initialize(message, code:)
      @code = code
      super(message)
    end
  end

  def initialize(current_account)
    @current_account = current_account
  end

  def handle(request_id:, method:, params: {})
    case method
    when "skills/list"
      success(request_id, skills: list_skills)
    when "skills/get"
      success(request_id, skill: get_skill(params))
    when "skills/purchase"
      success(request_id, purchase: purchase_skill(params))
    when "skills/acquire"
      success(request_id, acquire_skill(params))
    else
      raise Error.new("Method not found: #{method}", code: -32601)
    end
  end

  private

  def success(request_id, result)
    {
      jsonrpc: "2.0",
      id: request_id,
      result: result
    }
  end

  def list_skills
    publicly_listed_skills.filter_map do |skill|
      version = latest_verified_version_for(skill)
      next unless version

      verification = version.skill_verification
      artifact = version.skill_artifact

      {
        id: skill.id,
        slug: skill.slug,
        name: skill.name,
        description: skill.description,
        author: {
          id: skill.author.id,
          name: skill.author.name
        },
        price: skill.price.to_f,
        latest_version: {
          version: version.version,
          status: version.status,
          artifact_type: artifact.artifact_type
        },
        verification: {
          status: verification.status,
          publicly_listed: true,
          checks: verification.checks
        }
      }
    end
  end

  def get_skill(params)
    skill_id = params[:skill_id] || params["skill_id"]
    requested_version = params[:version] || params["version"]
    raise Error.new("skill_id is required", code: -32602) if skill_id.blank?

    skill = publicly_listed_skills.find(skill_id)
    version = if requested_version.present?
      skill.skill_versions
           .includes(:skill_artifact, :skill_verification)
           .find_by!(version: requested_version, status: "verified")
    else
      latest_verified_version_for(skill)
    end

    raise Error.new("Verified skill version not found", code: -32602) unless version&.skill_verification&.status == "verified"

    artifact = version.skill_artifact
    verification = version.skill_verification

    {
      id: skill.id,
      slug: skill.slug,
      name: skill.name,
      description: skill.description,
      author: {
        id: skill.author.id,
        name: skill.author.name
      },
      price: skill.price.to_f,
      version: version.version,
      manifest_summary: artifact.manifest.slice("name", "description", "runtime", "entrypoint", "input_schema", "output_schema"),
      checksum: artifact.checksum,
      verification: {
        status: verification.status,
        checks: verification.checks,
        verified_at: verification.verified_at
      }
    }
  rescue ActiveRecord::RecordNotFound
    raise Error.new("Verified skill not found", code: -32602)
  end

  def purchase_skill(params)
    skill_id = params[:skill_id] || params["skill_id"]
    version = params[:version] || params["version"]
    raise Error.new("skill_id is required", code: -32602) if skill_id.blank?
    raise Error.new("version is required", code: -32602) if version.blank?

    purchase = SkillPurchaseService.new(buyer: @current_account).call(skill_id: skill_id, version: version)

    {
      id: purchase.id,
      status: purchase.status,
      amount: purchase.amount.to_f,
      buyer_id: purchase.buyer_id,
      skill_id: purchase.skill_version.skill_id,
      version: purchase.skill_version.version,
      entitlement_token: purchase.entitlement_token
    }
  rescue ActiveRecord::RecordNotFound
    raise Error.new("Skill version not found", code: -32602)
  rescue SkillPurchaseService::Error => e
    raise Error.new(e.message, code: -32000)
  end

  def acquire_skill(params)
    purchase_id = params[:purchase_id] || params["purchase_id"]
    raise Error.new("purchase_id is required", code: -32602) if purchase_id.blank?

    SkillAcquisitionService.new(buyer: @current_account).call(purchase_id: purchase_id)
  rescue SkillAcquisitionService::Error => e
    raise Error.new(e.message, code: -32000)
  end

  def publicly_listed_skills
    Skill.includes(:author, skill_versions: [ :skill_artifact, :skill_verification ])
         .where(listing_status: "listed")
         .order(:id)
  end

  def latest_verified_version_for(skill)
    skill.skill_versions
         .select { |version| version.status == "verified" && version.skill_verification&.status == "verified" && version.skill_artifact.present? }
         .max_by(&:created_at)
  end
end

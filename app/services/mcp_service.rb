class McpService
  AUTHORIZATION_ERROR_CODE = -32001

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
    when "skills/create"
      success(request_id, skill: create_skill(params))
    when "skills/mine.list"
      success(request_id, skills: list_owned_skills)
    when "skills/version.publish"
      success(request_id, publication: publish_owned_version(params))
    when "skills/version.get"
      success(request_id, version: get_owned_version(params))
    when "skills/listing.set_status"
      success(request_id, skill: set_owned_listing_status(params))
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

      serialize_public_skill(skill, version)
    end
  end

  def list_owned_skills
    owned_skills.map do |skill|
      serialize_owned_skill(skill)
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

  def get_owned_version(params)
    skill = owned_skill_from_params(params)
    requested_version = params[:version] || params["version"]

    version = if requested_version.present?
      skill.skill_versions.find_by!(version: requested_version)
    else
      skill.skill_versions.max_by(&:created_at)
    end

    raise Error.new("Version not found", code: -32602) unless version

    serialize_owned_version(skill, version)
  rescue ActiveRecord::RecordNotFound
    raise Error.new("Version not found", code: -32602)
  end

  def publish_owned_version(params)
    skill = owned_skill_from_params(params)
    version = params[:version] || params["version"]
    changelog = params[:changelog] || params["changelog"]
    artifact = params[:artifact] || params["artifact"]

    raise Error.new("version is required", code: -32602) if version.blank?
    raise Error.new("artifact is required", code: -32602) if artifact.blank?

    symbolized_artifact = {
      artifact_type: artifact[:artifact_type] || artifact["artifact_type"],
      manifest: artifact[:manifest] || artifact["manifest"]
    }

    SkillVersionRegistrationService.new(skill: skill, author: @current_account).call(
      version: version,
      changelog: changelog,
      artifact: symbolized_artifact
    )
  rescue SkillVersionRegistrationService::AuthorizationError => e
    raise Error.new(e.message, code: AUTHORIZATION_ERROR_CODE)
  rescue SkillVersionRegistrationService::Error => e
    raise Error.new(e.message, code: -32602)
  end

  def set_owned_listing_status(params)
    skill = owned_skill_from_params(params)
    listing_status = params[:listing_status] || params["listing_status"]
    raise Error.new("listing_status is required", code: -32602) if listing_status.blank?

    updated_skill = SkillListingStatusService.new(skill: skill, actor: @current_account).call(
      listing_status: listing_status
    )

    serialize_owned_skill(updated_skill.reload)
  rescue SkillListingStatusService::AuthorizationError => e
    raise Error.new(e.message, code: AUTHORIZATION_ERROR_CODE)
  rescue SkillListingStatusService::Error => e
    raise Error.new(e.message, code: -32602)
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

  def owned_skills
    Skill.includes(:author, skill_versions: [ :skill_artifact, :skill_verification, :purchases ])
         .where(author_id: @current_account.id)
         .order(:id)
  end

  def owned_skill_from_params(params)
    skill_id = params[:skill_id] || params["skill_id"]
    raise Error.new("skill_id is required", code: -32602) if skill_id.blank?

    skill = owned_skills.find_by(id: skill_id)
    raise Error.new("You do not own this skill", code: AUTHORIZATION_ERROR_CODE) unless skill

    skill
  end

  def latest_verified_version_for(skill)
    skill.skill_versions
         .select { |version| version.status == "verified" && version.skill_verification&.status == "verified" && version.skill_artifact.present? }
         .max_by(&:created_at)
  end

  def latest_version_for(skill)
    skill.skill_versions.max_by(&:created_at)
  end

  def serialize_public_skill(skill, version)
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

  def serialize_owned_skill(skill)
    latest_version = latest_version_for(skill)
    {
      id: skill.id,
      slug: skill.slug,
      name: skill.name,
      description: skill.description,
      listing_status: skill.listing_status,
      price: skill.price.to_f,
      author: {
        id: skill.author.id,
        name: skill.author.name
      },
      latest_version: latest_version ? serialize_owned_version_summary(latest_version) : nil,
      purchase_summary: serialize_purchase_summary(skill),
      versions: skill.skill_versions.sort_by(&:created_at).reverse.map { |version| serialize_owned_version_summary(version) }
    }
  end

  def serialize_purchase_summary(skill)
    paid_purchases = skill.purchases.select(&:paid?)

    {
      paid_purchase_count: paid_purchases.count,
      gross_revenue: paid_purchases.sum { |purchase| purchase.amount.to_f },
      latest_purchase_at: paid_purchases.max_by(&:created_at)&.created_at
    }
  end

  def serialize_owned_version(skill, version)
    artifact = version.skill_artifact
    verification = version.skill_verification

    {
      skill: {
        id: skill.id,
        slug: skill.slug,
        name: skill.name,
        listing_status: skill.listing_status
      },
      version: version.version,
      changelog: version.changelog,
      status: version.status,
      artifact: artifact && {
        artifact_type: artifact.artifact_type,
        checksum: artifact.checksum,
        manifest_summary: artifact.manifest.slice("name", "description", "runtime", "entrypoint", "input_schema", "output_schema"),
        file_count: Array(artifact.manifest["files"]).size
      },
      verification: verification && {
        status: verification.status,
        checks: verification.checks,
        verified_at: verification.verified_at,
        failure_reason: verification.failure_reason
      },
      created_at: version.created_at,
      updated_at: version.updated_at
    }
  end

  def serialize_owned_version_summary(version)
    artifact = version.skill_artifact
    verification = version.skill_verification

    {
      id: version.id,
      version: version.version,
      status: version.status,
      artifact_type: artifact&.artifact_type,
      verification_status: verification&.status,
      failure_reason: verification&.failure_reason,
      created_at: version.created_at
    }
  end

  def create_skill(params)
    creation_params = {
      name: params[:name] || params["name"],
      description: params[:description] || params["description"],
      price: params[:price] || params["price"],
      author_id: @current_account.id
    }

    requested_listing_status = (params[:listing_status] || params["listing_status"]).presence
    skill = nil

    Skill.transaction do
      result = SkillCreationService.new(creation_params).call
      skill = Skill.includes(:author).find(result["id"])

      if requested_listing_status.present? && requested_listing_status != "draft"
        SkillListingStatusService.new(skill: skill, actor: @current_account).call(listing_status: requested_listing_status)
        skill.reload
      end
    end

    serialize_owned_skill(skill)
  rescue SkillListingStatusService::AuthorizationError => e
    raise Error.new(e.message, code: AUTHORIZATION_ERROR_CODE)
  rescue SkillCreationService::Error, SkillListingStatusService::Error => e
    raise Error.new(e.message, code: -32602)
  end
end

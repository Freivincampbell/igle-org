module ChurchAdmin
  class MembersController < BaseController
    before_action :set_member, only: %i[show edit update activate deactivate]
    before_action :set_user_options, only: %i[new create edit update]
    before_action :set_form_catalog, only: %i[edit update]

    def index
      authorize Member

      base = policy_scope(Member).where(church: @church)
      base = base.search_by_name(params[:q]) if params[:q].present?
      base = base.where(member_status: params[:status]) if params[:status].present?

      @pagy, @members = pagy(base.ordered, limit: 25)
    end

    def search
      authorize Member

      query = params[:q].to_s.strip
      @results = if query.length < 2
        Member.none
      else
        policy_scope(Member)
          .where(church: @church)
          .where.not(public_id: Array(params[:exclude]))
          .search_by_name(query)
          .reorder(:last_name, :first_name)
          .limit(10)
      end

      @frame_id = params[:frame_id].to_s.gsub(/[^a-zA-Z0-9_-]/, "").presence || "member-search-results"

      render layout: false
    end

    def show
      authorize @member

      @ministry_memberships = @member.ministry_memberships
        .active
        .includes(:ministry)
        .joins(:ministry)
        .where(ministries: { church_id: @church.id })
        .order("ministries.name")

      @member_occupations = @member.member_occupations
        .includes(:occupation)
        .joins(:occupation)
        .where(occupations: { church_id: @church.id })
        .order("occupations.name")

      @member_skills = @member.member_skills
        .includes(:skill)
        .joins(:skill)
        .where(skills: { church_id: @church.id })
        .order("skills.name")
    end

    def new
      @member = @church.members.new(default_member_attributes)
      authorize @member
    end

    def create
      @member = @church.members.new(member_params)
      authorize @member

      if @member.save
        assign_catalog_items(@member)
        redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.members.created")
      else
        render :new, status: :unprocessable_content
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to church_admin_member_path(@church, @member),
        alert: t("church_admin.member_ministries.invalid_ministry")
    end

    def edit
      authorize @member
    end

    def update
      authorize @member

      if @member.update(member_params)
        assign_catalog_items(@member)
        redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.members.updated")
      else
        render :edit, status: :unprocessable_content
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to church_admin_member_path(@church, @member),
        alert: t("church_admin.member_ministries.invalid_ministry")
    end

    def activate
      authorize @member
      @member.active!

      redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.members.activated")
    end

    def deactivate
      authorize @member
      @member.inactive!

      redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.members.deactivated")
    end

    private

    def set_member
      @member = @church.members.find_by_public_id!(params[:public_id])
    end

    def set_user_options
      @user_options = @church.church_memberships
        .active
        .joins(:user)
        .includes(:user)
        .order("users.email")
        .map { |membership| [ membership.user.email, membership.user_id ] }
    end

    def member_params
      params.require(:member).permit(
        :user_id,
        :first_name,
        :middle_name,
        :last_name,
        :second_last_name,
        :email,
        :phone,
        :secondary_phone,
        :birth_date,
        :gender,
        :marital_status,
        :children_count,
        :baptized_on,
        :official_membership_on,
        :member_status,
        :address_line_1,
        :address_line_2,
        :city,
        :state,
        :postal_code,
        :country,
        :emergency_contact_name,
        :emergency_contact_phone,
        :notes,
        :photo
      )
    end

    def default_member_attributes
      {
        member_status: "active",
        children_count: 0,
        country: @church.country
      }
    end

    def set_form_catalog
      @form_occupations = @member.member_occupations
        .includes(:occupation).joins(:occupation)
        .where(occupations: { church_id: @church.id }).order("occupations.name")
      @form_skills = @member.member_skills
        .includes(:skill).joins(:skill)
        .where(skills: { church_id: @church.id }).order("skills.name")
      @form_ministries = @member.ministry_memberships
        .active.includes(:ministry).joins(:ministry)
        .where(ministries: { church_id: @church.id }).order("ministries.name")
    end

    def assign_catalog_items(member)
      # Ocupaciones
      if params[:occupation_section_submitted] == "1"
        occ_names     = Array(params[:occupation_names]).map(&:strip).reject(&:blank?).uniq
        offers_names  = Array(params[:offers_services])
        looking_names = Array(params[:looking_for_work])
        kept_ids = occ_names.map { |n| @church.occupations.find_or_create_by!(name: n) { |o| o.status = "active" }.id }
        member.member_occupations.where.not(occupation_id: kept_ids).destroy_all
        occ_names.each do |name|
          occ = @church.occupations.find_or_create_by!(name: name) { |o| o.status = "active" }
          mo  = member.member_occupations.find_or_initialize_by(occupation: occ, church: @church)
          mo.employment_status = "employed" if mo.new_record?
          mo.offers_services   = offers_names.include?(name)
          mo.looking_for_work  = looking_names.include?(name)
          mo.save!
        end
      end

      # Habilidades
      if params[:skill_section_submitted] == "1"
        skill_data = Array(params[:skills])
          .map { |s| { name: s[:name].to_s.strip, level: s[:level].to_s.presence || "basic", offers_service: s[:offers_service] == "1" } }
          .reject { |s| s[:name].blank? }.uniq { |s| s[:name] }
        kept_ids = skill_data.map { |s| @church.skills.find_or_create_by!(name: s[:name]) { |sk| sk.status = "active" }.id }
        member.member_skills.where.not(skill_id: kept_ids).destroy_all
        skill_data.each do |s|
          sk = @church.skills.find_or_create_by!(name: s[:name]) { |sk| sk.status = "active" }
          ms = member.member_skills.find_or_initialize_by(skill: sk, church: @church)
          ms.level = s[:level]
          ms.offers_service = s[:offers_service]
          ms.save!
        end
      end

      # Ministerios
      return unless params[:ministry_memberships_submitted] == "1"

      raw = params.key?(:ministry_memberships) ? params[:ministry_memberships].to_unsafe_h : {}
      entries = raw.map { |pub_id, attrs|
        { public_id: pub_id.to_s, role: (attrs["role"].presence || "member").to_s }
      }.reject { |e| e[:public_id].blank? }.uniq { |e| e[:public_id] }
      ministries = entries.map { |e| @church.ministries.active.find_by!(public_id: e[:public_id]) }
      member.ministry_memberships.active
        .where.not(ministry_id: ministries.map(&:id))
        .find_each(&:inactive!)
      entries.each do |e|
        ministry = ministries.find { |m| m.public_id == e[:public_id] }
        mm = member.ministry_memberships.find_or_initialize_by(ministry:)
        mm.ministry_role = e[:role]
        mm.status = "active"
        mm.save!
      end
    end
  end
end

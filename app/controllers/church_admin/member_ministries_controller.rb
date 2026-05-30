module ChurchAdmin
  class MemberMinistriesController < BaseController
    before_action :set_member

    def assign
      authorize @member, :update?

      raw = params.key?(:ministry_memberships) ? params[:ministry_memberships].to_unsafe_h : {}
      entries = raw.map do |public_id, attrs|
        { public_id: public_id.to_s, role: (attrs["role"].presence || "member").to_s }
      end.reject { |e| e[:public_id].blank? }.uniq { |e| e[:public_id] }

      ActiveRecord::Base.transaction do
        ministries = entries.map do |e|
          @church.ministries.active.find_by!(public_id: e[:public_id])
        end

        @member.ministry_memberships.active
          .where.not(ministry_id: ministries.map(&:id))
          .find_each(&:inactive!)

        entries.each do |e|
          ministry = ministries.find { |m| m.public_id == e[:public_id] }
          mm = @member.ministry_memberships.find_or_initialize_by(ministry:)
          mm.ministry_role = e[:role]
          mm.status = "active"
          mm.save!
        end
      end

      redirect_to church_admin_member_path(@church, @member),
        notice: t("church_admin.member_ministries.updated")
    rescue ActiveRecord::RecordNotFound
      redirect_to church_admin_member_path(@church, @member),
        alert: t("church_admin.member_ministries.invalid_ministry")
    end

    private

    def set_member
      @member = @church.members.find_by_public_id!(params[:public_id])
    end
  end
end

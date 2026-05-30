module ChurchAdmin
  class SettingsController < BaseController
    def show
      authorize @church, policy_class: ChurchSettingPolicy
    end

    def update
      authorize @church, :update?, policy_class: ChurchSettingPolicy

      if @church.update(church_settings_params)
        redirect_to church_admin_settings_path(@church), notice: t("church_admin.settings.updated")
      else
        render :show, status: :unprocessable_content
      end
    end

    def check_slug
      authorize @church, :update?, policy_class: ChurchSettingPolicy

      slug = params[:slug].to_s.strip.downcase.presence

      unless slug&.match?(/\A[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?\z/)
        render json: { available: false, reason: "invalid_format" }
        return
      end

      taken = Church.where(slug:).where.not(id: @church.id).exists?

      if taken
        render json: { available: false, reason: "taken" }
      else
        render json: { available: true }
      end
    end

    private

    def church_settings_params
      attrs = params.require(:church).permit(
        :name,
        :legal_name,
        :slug,
        :description,
        :email,
        :phone,
        :whatsapp,
        :website,
        :facebook_url,
        :instagram_url,
        :youtube_url,
        :address_line_1,
        :address_line_2,
        :city,
        :state,
        :postal_code,
        :country,
        :primary_color,
        :secondary_color,
        :locale,
        :time_zone,
        :public_page_enabled,
        :service_directory_enabled,
        :member_work_contact_enabled,
        :logo
      )

      logo = attrs[:logo]
      attrs.delete(:logo) if logo.blank? || (logo.respond_to?(:size) && logo.size.zero?)

      attrs
    end
  end
end

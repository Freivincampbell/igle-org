module Pastor
  class PastoralNotesController < BaseController
    before_action :set_note, only: %i[show edit update destroy]
    before_action :set_member_options, only: %i[new create edit update]

    def index
      authorize PastoralNote
      @notes = policy_scope(PastoralNote).where(church: @church).includes(:member, :pastor).ordered
    end

    def show
      authorize @note
    end

    def new
      @note = @church.pastoral_notes.new(pastor: current_user, note_type: "general")
      authorize @note
    end

    def create
      @note = @church.pastoral_notes.new(note_params.merge(pastor: current_user, member: resolve_member))
      authorize @note

      if @note.save
        redirect_to church_pastor_pastoral_note_path(@church, @note), notice: t("pastor.pastoral_notes.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @note
    end

    def update
      authorize @note

      if @note.update(note_params.merge(member: resolve_member))
        redirect_to church_pastor_pastoral_note_path(@church, @note), notice: t("pastor.pastoral_notes.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize @note
      @note.destroy
      redirect_to church_pastor_pastoral_notes_path(@church), notice: t("pastor.pastoral_notes.removed")
    end

    private

    def set_note
      @note = @church.pastoral_notes.find_by_public_id!(params[:public_id])
    end

    def set_member_options
      @member_options = @church.members.active.ordered.map { |m| [ m.full_name, m.public_id ] }
    end

    def resolve_member
      public_id = params.dig(:pastoral_note, :member_public_id)
      return nil if public_id.blank?

      @church.members.find_by_public_id!(public_id)
    end

    def note_params
      params.require(:pastoral_note).permit(:title, :body, :note_type)
    end
  end
end

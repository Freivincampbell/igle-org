module ChurchAdmin
  class BoardsController < BaseController
    before_action :set_board, only: %i[show edit update activate deactivate update_positions]
    before_action :set_member_options, only: %i[show update_positions]

    def index
      authorize Board

      @boards = policy_scope(Board).where(church: @church).ordered.includes(:board_members)
    end

    def show
      authorize @board
    end

    def new
      @board = @church.boards.new(status: "active", starts_on: Date.current)
      authorize @board
    end

    def create
      @board = @church.boards.new(board_params)
      authorize @board

      if @board.save
        redirect_to church_admin_board_path(@church, @board), notice: t("church_admin.boards.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @board
    end

    def update
      authorize @board

      if @board.update(board_params)
        redirect_to church_admin_board_path(@church, @board), notice: t("church_admin.boards.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def activate
      authorize @board
      @board.active!
      redirect_to church_admin_board_path(@church, @board), notice: t("church_admin.boards.activated")
    end

    def deactivate
      authorize @board
      @board.inactive!
      redirect_to church_admin_board_path(@church, @board), notice: t("church_admin.boards.deactivated")
    end

    def update_positions
      authorize @board, :update?

      assignment = Boards::PositionAssignment.new(
        board: @board,
        assignments_payload: params.fetch(:board, {}).fetch(:positions, {}).to_unsafe_h
      )

      if assignment.save
        redirect_to church_admin_board_path(@church, @board), notice: t("church_admin.boards.positions_updated")
      else
        assignment.errors.full_messages.each { |m| @board.errors.add(:base, m) }
        render :show, status: :unprocessable_content
      end
    end

    private

    def set_board
      @board = @church.boards.find_by_public_id!(params[:public_id])
    end

    def set_member_options
      @current_positions = @board.board_members.includes(:member).index_by(&:position)
    end

    def board_params
      params.require(:board).permit(:name, :starts_on, :ends_on, :status, :notes)
    end
  end
end

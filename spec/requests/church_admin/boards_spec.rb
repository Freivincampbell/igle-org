require "rails_helper"

RSpec.describe "Church admin boards" do
  describe "access control" do
    it "requires authentication" do
      church = create(:church)

      get church_admin_boards_path(church)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "rejects users without access to the church" do
      church = create(:church)
      sign_in create(:user)

      get church_admin_boards_path(church)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST create" do
    it "creates a board" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      expect do
        post church_admin_boards_path(church), params: {
          board: { name: "Junta 2026", starts_on: Date.current.iso8601, ends_on: (Date.current + 2.years).iso8601, status: "active" }
        }
      end.to change(Board, :count).by(1)
    end
  end

  describe "PATCH update_positions" do
    it "assigns each position to an active member of the same church" do
      church = create(:church)
      foreign_member = create(:member)
      membership = create(:church_membership, :owner, church:)
      board = create(:board, church:)
      pres = create(:member, church:, first_name: "Pedro")
      vp = create(:member, church:, first_name: "Vicky")

      sign_in membership.user

      patch positions_church_admin_board_path(church, board), params: {
        board: {
          positions: {
            "president" => pres.public_id,
            "vice_president" => vp.public_id,
            "treasurer" => foreign_member.public_id
          }
        }
      }

      expect(board.board_members.pluck(:position).sort).to eq([ "president", "vice_president" ])
      assignments = board.board_members.index_by(&:position)
      expect(assignments["president"].member).to eq(pres)
      expect(assignments["vice_president"].member).to eq(vp)
    end

    it "rejects assigning the same member to two positions" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      board = create(:board, church:)
      pedro = create(:member, church:)

      sign_in membership.user

      patch positions_church_admin_board_path(church, board), params: {
        board: {
          positions: {
            "president" => pedro.public_id,
            "vice_president" => pedro.public_id
          }
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(board.board_members.count).to eq(0)
    end
  end

  describe "public id routing" do
    it "does not resolve board database ids" do
      church = create(:church)
      board = create(:board, church:)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      get "/churches/#{church.public_id}/admin/boards/#{board.id}"

      expect(response).to have_http_status(:not_found)
    end
  end
end

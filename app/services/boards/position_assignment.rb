module Boards
  class PositionAssignment
    include ActiveModel::Model

    attr_accessor :board, :assignments_payload

    def save
      assignments = build_assignments
      return false if errors.any?

      ActiveRecord::Base.transaction do
        board.board_members.destroy_all
        assignments.each do |a|
          board.board_members.create!(
            church: board.church,
            position: a[:position],
            member: a[:member],
            status: "active"
          )
        end
      end

      true
    end

    private

    def build_assignments
      assignments = []
      seen_positions = []
      seen_members = []

      Array(assignments_payload).each do |position, member_public_id|
        next if member_public_id.blank?
        next unless BoardMember::POSITIONS.include?(position.to_s)
        if seen_positions.include?(position.to_s)
          errors.add(:base, "Cargo duplicado: #{position}")
          next
        end

        member = board.church.members.active.find_by(public_id: member_public_id)
        next unless member

        if seen_members.include?(member.id)
          errors.add(:base, "Miembro #{member.full_name} ya esta asignado en esta junta")
          next
        end

        seen_positions << position.to_s
        seen_members << member.id
        assignments << { position: position.to_s, member: member }
      end

      assignments
    end
  end
end

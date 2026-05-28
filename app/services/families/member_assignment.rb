module Families
  class MemberAssignment
    include ActiveModel::Model

    attr_accessor :family, :member_public_ids, :member_relationships, :primary_contact_public_id

    def save
      assignments = build_assignments

      ActiveRecord::Base.transaction do
        if assignments.any?
          family.family_members.where.not(member_id: assignments.map { |a| a[:member].id }).destroy_all
        else
          family.family_members.destroy_all
        end

        assignments.each do |a|
          fm = family.family_members.find_or_initialize_by(member: a[:member])
          fm.church = family.church
          fm.relationship = a[:relationship]
          fm.primary_contact = a[:primary]
          fm.save!
        end
      end

      true
    end

    private

    def build_assignments
      Array(member_public_ids).filter_map do |public_id|
        member = family.church.members.find_by(public_id: public_id)
        next unless member

        {
          member: member,
          relationship: member_relationships&.dig(public_id) || "other",
          primary: primary_contact_public_id.to_s == public_id.to_s
        }
      end
    end
  end
end

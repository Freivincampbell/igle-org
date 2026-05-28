module Ministries
  class MemberAssignment
    include ActiveModel::Model

    attr_accessor :ministry, :member_public_ids, :member_roles

    validates :ministry, presence: true
    validate :selected_members_exist
    validate :selected_roles_are_valid

    def save
      return false unless valid?

      ActiveRecord::Base.transaction do
        ministry.ministry_memberships.active.where.not(member_id: selected_members.map(&:id)).find_each(&:inactive!)

        selected_members.each do |member|
          ministry_membership = ministry.ministry_memberships.find_or_initialize_by(member:)
          ministry_membership.ministry_role = role_for(member.public_id)
          ministry_membership.status = "active"
          ministry_membership.save!
        end
      end

      true
    rescue ActiveRecord::RecordInvalid => error
      errors.add(:base, error.record.errors.full_messages.to_sentence)
      false
    end

    private

    def selected_members
      return [] if ministry.blank?

      @selected_members ||= ministry.church.members.active.where(public_id: normalized_member_public_ids).to_a
    end

    def normalized_member_public_ids
      Array(member_public_ids).compact_blank.uniq
    end

    def normalized_member_roles
      @normalized_member_roles ||= if member_roles.respond_to?(:to_unsafe_h)
        member_roles.to_unsafe_h
      elsif member_roles.respond_to?(:to_h)
        member_roles.to_h
      else
        {}
      end
    end

    def role_for(member_public_id)
      normalized_member_roles.fetch(member_public_id, "member").presence || "member"
    end

    def selected_members_exist
      return if ministry.blank?
      return if normalized_member_public_ids.size == selected_members.size

      errors.add(:base, :invalid)
    end

    def selected_roles_are_valid
      return if ministry.blank?

      invalid_roles = normalized_member_public_ids.map { |public_id| role_for(public_id) } - MinistryMembership.ministry_roles.keys
      return if invalid_roles.empty?

      errors.add(:base, :invalid)
    end
  end
end

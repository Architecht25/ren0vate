# V2 — Lot 4 : poster dans un fil suit exactement les mêmes règles que le
# voir — pas de droit de réponse sans droit de lecture.
class MessagePolicy < ApplicationPolicy
  def create?
    MessageThreadPolicy.new(user, record.message_thread).show?
  end
end

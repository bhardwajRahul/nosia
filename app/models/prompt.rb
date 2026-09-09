class Prompt < ApplicationRecord
  belongs_to :account, optional: true
  belongs_to :user, optional: true

  # A blank system prompt would silently strip the model's instructions.
  validates :content, presence: true

  def full_name
    if account.present?
      case name
      when "system_prompt"
        "System Prompt for #{account.name} Account"
      end
    else
      case name
      when "system_prompt"
        "Default System Prompt"
      end
    end
  end
end

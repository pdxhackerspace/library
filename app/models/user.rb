class User < ApplicationRecord
  has_secure_password validations: false

  has_many :loans, dependent: :restrict_with_error

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :provider, uniqueness: { scope: :uid }, allow_nil: true

  before_validation :normalize_email
  before_save :prevent_manual_role_changes

  scope :admins, -> { where(admin: true) }
  scope :editors, -> { where(editor: true) }

  attr_accessor :syncing_roles_from_oidc

  def self.from_omniauth(auth)
    email = auth.info.email&.downcase
    return nil if email.blank?

    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)
    user.email = email
    user.name = auth.info.name.presence || email.split('@').first
    sync_slack_from_omniauth!(user, auth)
    user.save!
    sync_roles_from_omniauth!(user, auth)
    user
  end

  def self.sync_slack_from_omniauth!(user, auth)
    slack = OidcProfile.slack_info(auth)
    if slack
      user.slack_uid = slack[:uid]
      user.slack_name = slack[:name]
    else
      user.slack_uid = nil
      user.slack_name = nil
    end
  end

  def slack_linked?
    slack_uid.present?
  end

  def self.sync_roles_from_omniauth!(user, auth)
    user.syncing_roles_from_oidc = true
    user.update!(
      admin: OidcScopes.admin?(auth),
      editor: OidcScopes.editor?(auth)
    )
  ensure
    user.syncing_roles_from_oidc = false
  end

  def local_account?
    provider.blank?
  end

  def admin?
    return true if bootstrap_admin?

    self[:admin]
  end

  def editor?
    self[:editor]
  end

  def can_manage_books?
    admin? || editor?
  end

  def bootstrap_admin?
    local_account? && email == AdminBootstrap.admin_email
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def prevent_manual_role_changes
    return if syncing_roles_from_oidc
    return unless persisted?

    self.admin = admin_in_database if admin_changed?
    self.editor = editor_in_database if editor_changed?
  end
end

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
    user.save!
    sync_roles_from_omniauth!(user, auth)
    user
  end

  def self.sync_roles_from_omniauth!(user, auth)
    user.syncing_roles_from_oidc = true
    user.update!(
      admin: OidcClaims.admin?(auth),
      editor: OidcClaims.editor?(auth)
    )
  ensure
    user.syncing_roles_from_oidc = false
  end

  def self.role_from_omniauth(auth, claim_key)
    case claim_key
    when :is_admin then OidcClaims.admin?(auth)
    when :is_editor then OidcClaims.editor?(auth)
    else
      ActiveModel::Type::Boolean.new.cast(OidcClaims.value_for(auth, claim_key)) || false
    end
  end

  def self.extract_claim(source, key)
    OidcClaims.extract(source, key)
  end
  private_class_method :extract_claim

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

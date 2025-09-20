# Architecture Collaboration Professionnels - Ren0vate

## 🎯 Vision
Extension de Ren0vate pour intégrer architectes et entrepreneurs dans les projets clients avec un écosystème BtoB collaboratif sécurisé.

## 🏗️ Architecture Multi-Acteurs

### 1. Modèle de données étendu

#### ProjectCollaboration
```ruby
# app/models/project_collaboration.rb
class ProjectCollaboration < ApplicationRecord
  belongs_to :property
  belongs_to :collaborator, class_name: 'User'

  enum role: {
    architect: 'architect',
    contractor: 'contractor',
    engineer: 'engineer',
    consultant: 'consultant'
  }

  enum status: {
    invited: 'invited',
    active: 'active',
    suspended: 'suspended',
    completed: 'completed'
  }

  # Permissions granulaires
  jsonb :permissions, default: {}
  # { "documents": ["read", "write"], "simulations": ["read"], "timeline": ["read", "write"] }
end
```

#### Extension User Model
```ruby
# Extension du modèle User
class User < ApplicationRecord
  enum user_type: {
    particulier: 'particulier',
    entreprise: 'entreprise',
    architect: 'architect',
    contractor: 'contractor',
    consultant: 'consultant'
  }

  # Profil professionnel
  has_one :professional_profile
  has_many :project_collaborations, foreign_key: 'collaborator_id'
  has_many :collaborative_properties, through: :project_collaborations, source: :property
end
```

#### ProfessionalProfile
```ruby
# app/models/professional_profile.rb
class ProfessionalProfile < ApplicationRecord
  belongs_to :user

  # Informations professionnelles
  string :company_name
  string :registration_number  # Numéro d'ordre architecte/entrepreneur
  string :specialization
  text :certifications
  string :insurance_number

  # Validation métier
  validates :registration_number, presence: true, if: :architect_or_contractor?
end
```

### 2. Système d'invitations et d'accès

```ruby
# app/services/project_collaboration_service.rb
class ProjectCollaborationService
  def invite_professional(property, professional_email, role, permissions)
    professional = find_or_create_professional(professional_email, role)

    collaboration = ProjectCollaboration.create!(
      property: property,
      collaborator: professional,
      role: role,
      permissions: permissions,
      status: 'invited'
    )

    send_invitation_email(collaboration)
    collaboration
  end

  def accept_invitation(collaboration, professional)
    collaboration.update!(status: 'active')
    setup_professional_dashboard(collaboration)
  end

  private

  def default_permissions_for_role(role)
    case role
    when 'architect'
      {
        "documents": ["read", "write"],
        "plans": ["read", "write"],
        "simulations": ["read"],
        "timeline": ["read", "write"],
        "meetings": ["read", "write"]
      }
    when 'contractor'
      {
        "documents": ["read", "write"],
        "photos": ["read", "write"],
        "invoices": ["read", "write"],
        "timeline": ["read"],
        "materials": ["read", "write"]
      }
    end
  end
end
```

### 3. Interface différenciée par rôle

```ruby
# app/controllers/professional_dashboard_controller.rb
class ProfessionalDashboardController < ApplicationController
  before_action :authenticate_professional!
  before_action :load_active_projects

  def index
    @projects = current_user.collaborative_properties
                           .joins(:project_collaborations)
                           .where(project_collaborations: { status: 'active' })

    @pending_tasks = load_pending_tasks_by_role
    @recent_updates = load_recent_project_updates
  end

  def project_detail
    @property = find_authorized_property(params[:id])
    @collaboration = current_collaboration(@property)
    @permissions = @collaboration.permissions

    case current_user.user_type
    when 'architect'
      render 'architect_project_view'
    when 'contractor'
      render 'contractor_project_view'
    end
  end

  private

  def find_authorized_property(property_id)
    current_user.collaborative_properties.find(property_id)
  end
end
```

### 4. Espaces de travail spécialisés

#### Interface Architecte
```erb
<!-- app/views/professional_dashboard/architect_project_view.html.erb -->
<div class="architect-workspace">
  <div class="row">
    <!-- Plans et documents techniques -->
    <div class="col-md-6">
      <div class="card">
        <div class="card-header">
          <h5>📐 Plans et Documents Techniques</h5>
        </div>
        <div class="card-body">
          <%= render 'documents/technical_plans',
                     documents: @property.documents.technical,
                     can_edit: can_write?('plans') %>
        </div>
      </div>
    </div>

    <!-- Réglementations et contraintes -->
    <div class="col-md-6">
      <div class="card">
        <div class="header">
          <h5>📋 Contraintes Réglementaires</h5>
        </div>
        <div class="card-body">
          <%= render 'regulatory_constraints', property: @property %>
        </div>
      </div>
    </div>
  </div>

  <!-- Timeline collaborative -->
  <div class="row mt-4">
    <div class="col-12">
      <%= render 'shared/collaborative_timeline',
                 property: @property,
                 role: 'architect' %>
    </div>
  </div>
</div>
```

#### Interface Entrepreneur
```erb
<!-- app/views/professional_dashboard/contractor_project_view.html.erb -->
<div class="contractor-workspace">
  <!-- Photos de chantier -->
  <div class="card mb-4">
    <div class="card-header">
      <h5>📸 Suivi Photographique</h5>
    </div>
    <div class="card-body">
      <%= render 'construction_photos',
                 photos: @property.construction_photos,
                 can_upload: can_write?('photos') %>
    </div>
  </div>

  <!-- Factures et matériaux -->
  <div class="row">
    <div class="col-md-8">
      <%= render 'invoices_management', property: @property %>
    </div>
    <div class="col-md-4">
      <%= render 'materials_tracker', property: @property %>
    </div>
  </div>
</div>
```

### 5. Système de notifications collaborative

```ruby
# app/models/collaborative_notification.rb
class CollaborativeNotification < ApplicationRecord
  belongs_to :property
  belongs_to :sender, class_name: 'User'
  belongs_to :recipient, class_name: 'User'

  enum notification_type: {
    document_uploaded: 'document_uploaded',
    milestone_reached: 'milestone_reached',
    approval_requested: 'approval_requested',
    meeting_scheduled: 'meeting_scheduled'
  }

  scope :unread, -> { where(read_at: nil) }

  def notify_collaborators!
    property.project_collaborations.active.each do |collaboration|
      next if collaboration.collaborator == sender

      CollaborativeNotificationMailer
        .new_notification(self, collaboration.collaborator)
        .deliver_later
    end
  end
end
```

### 6. Gestion des permissions granulaires

```ruby
# app/services/permission_service.rb
class PermissionService
  def initialize(user, property)
    @user = user
    @property = property
    @collaboration = find_collaboration
  end

  def can?(action, resource)
    return true if @property.user == @user  # Propriétaire
    return false unless @collaboration&.active?

    permissions = @collaboration.permissions
    permissions.dig(resource.to_s, "permissions")&.include?(action.to_s)
  end

  def can_read?(resource)
    can?('read', resource)
  end

  def can_write?(resource)
    can?('write', resource)
  end

  def can_delete?(resource)
    can?('delete', resource)
  end
end
```

#### Helper pour les vues
```ruby
# Helper pour les vues
module CollaborationHelper
  def can_read?(resource)
    permission_service.can_read?(resource)
  end

  def can_write?(resource)
    permission_service.can_write?(resource)
  end

  private

  def permission_service
    @permission_service ||= PermissionService.new(current_user, @property)
  end
end
```

## 🎯 Plan de déploiement

### Phase 1 : Infrastructure de base
- [ ] Extension modèles User/Property
- [ ] Système d'invitations
- [ ] Interface basique professionnels
- [ ] Authentification multi-rôles

### Phase 2 : Espaces de travail spécialisés
- [ ] Dashboard architecte
- [ ] Dashboard entrepreneur
- [ ] Gestion documents par rôle
- [ ] Upload spécialisé (plans, photos, factures)

### Phase 3 : Collaboration avancée
- [ ] Timeline collaborative
- [ ] Notifications en temps réel
- [ ] Workflow d'approbations
- [ ] Commentaires et annotations
- [ ] Versioning de documents

## 🔐 Sécurité et permissions

### Matrice des permissions par rôle

| Ressource | Propriétaire | Architecte | Entrepreneur | Consultant |
|-----------|--------------|------------|--------------|------------|
| Simulation | RW | R | R | R |
| Documents techniques | RW | RW | R | R |
| Plans | RW | RW | R | R |
| Photos chantier | RW | R | RW | R |
| Factures | RW | R | RW | R |
| Timeline | RW | RW | R | RW |
| Réunions | RW | RW | R | RW |

**Légende :** R = Read, W = Write, RW = Read/Write

## 🚀 Avantages de cette architecture

### Pour les propriétaires
- ✅ Contrôle total sur les accès
- ✅ Suivi en temps réel des travaux
- ✅ Centralisation de tous les documents
- ✅ Historique complet du projet

### Pour les architectes
- ✅ Accès direct aux contraintes réglementaires
- ✅ Collaboration fluide avec entrepreneurs
- ✅ Gestion centralisée des plans
- ✅ Suivi des validations clients

### Pour les entrepreneurs
- ✅ Documentation photographique intégrée
- ✅ Gestion des factures et matériaux
- ✅ Communication directe avec architectes
- ✅ Suivi des jalons projet

### Pour l'écosystème Ren0vate
- ✅ Extension naturelle du BtoC vers BtoB
- ✅ Monétisation via abonnements professionnels
- ✅ Données enrichies pour améliorer les simulations
- ✅ Réseau de professionnels qualifiés

## 🔧 Technologies recommandées

- **Backend** : Rails 8 avec ActionCable pour temps réel
- **Frontend** : Stimulus + Turbo pour interactivité
- **Stockage** : ActiveStorage + S3 pour documents
- **Notifications** : ActionMailer + pusher/websockets
- **Permissions** : CanCanCan ou Pundit
- **API** : REST avec authentification JWT pour mobiles

## 📊 Métriques de succès

- Nombre de professionnels actifs
- Projets collaboratifs créés par mois
- Documents échangés par projet
- Temps de réalisation des projets
- Satisfaction client (NPS)
- Réduction des erreurs de communication

---

*Document créé le 20 septembre 2025 - Architecture Collaboration Professionnels Ren0vate*

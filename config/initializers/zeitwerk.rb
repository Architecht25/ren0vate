# Rangement de app/models/ en sous-dossiers thématiques (14/09/2026) sans
# namespacer les classes : Property reste Property, Document reste Document...
#
# Pourquoi pas un namespace (Property::Property) comme pour app/services/ ?
# Trois risques identifiés spécifiques aux modèles ActiveRecord :
#   - active_storage_attachments.record_type stocke le nom de classe en base
#     (Document, Property, Request, RequestProgress, ComplementRequest,
#     PvReception, Reserve) — un renommage rendrait les fichiers déjà
#     uploadés orphelins sans migration de données.
#   - STI latent : notifications.type et properties.type sont des colonnes
#     réelles avec self.inheritance_column = nil pour désactiver l'héritage
#     Rails. Un renommage sans reporter cette ligne réactiverait STI et
#     ferait planter le chargement des enregistrements existants.
#   - GlobalID via Solid Queue : plusieurs mailers (UserMailer,
#     NotificationMailer, ComplementRequestMailer...) reçoivent l'objet AR
#     directement → deliver_later sérialise gid://app/User/42 en base. Un
#     renommage pendant qu'un job est en attente le ferait échouer au
#     déploiement.
#
# Rails.autoloaders.main.collapse indique à Zeitwerk que ces dossiers ne
# sont PAS des namespaces : leur contenu est chargé comme s'il était à la
# racine de app/models/. Aucun appelant à mettre à jour.
Rails.autoloaders.main.collapse("#{Rails.root}/app/models/property")
Rails.autoloaders.main.collapse("#{Rails.root}/app/models/project")
Rails.autoloaders.main.collapse("#{Rails.root}/app/models/documents")
Rails.autoloaders.main.collapse("#{Rails.root}/app/models/devis")
Rails.autoloaders.main.collapse("#{Rails.root}/app/models/subsidies")
Rails.autoloaders.main.collapse("#{Rails.root}/app/models/user")
Rails.autoloaders.main.collapse("#{Rails.root}/app/models/admin")
Rails.autoloaders.main.collapse("#{Rails.root}/app/models/business_intelligence")
Rails.autoloaders.main.collapse("#{Rails.root}/app/models/notifications")
Rails.autoloaders.main.collapse("#{Rails.root}/app/models/catalogue")

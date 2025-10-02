class ApplicationMailbox < ActionMailbox::Base
  # Router tous les emails vers les domaines tracking (production et développement) vers TrackingMailbox
  routing /@tracking\.(ren0vate\.be|example\.com)$/i => :tracking
end

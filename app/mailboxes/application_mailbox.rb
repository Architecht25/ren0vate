class ApplicationMailbox < ActionMailbox::Base
  # Router tous les emails vers le domaine tracking.ren0vate.be vers TrackingMailbox
  routing /@tracking\.ren0vate\.be$/i => :tracking
end

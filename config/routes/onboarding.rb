  scope '/onboarding', as: :onboarding do
    get  'profil',                     to: 'onboarding#profile_selection',              as: :profile_selection
    post 'profil',                     to: 'onboarding#set_profile',                    as: :set_profile

    get  'proprietaire/bien',          to: 'onboarding#proprietaire_bien',              as: :proprietaire_bien
    post 'proprietaire/bien',          to: 'onboarding#create_proprietaire_bien',       as: :create_proprietaire_bien

    get  'proprietaire/projet',        to: 'onboarding#proprietaire_projet',            as: :proprietaire_projet
    post 'proprietaire/projet',        to: 'onboarding#create_proprietaire_projet',     as: :create_proprietaire_projet

    get  'architecte/profil-pro',      to: 'onboarding#architecte_profil',              as: :architecte_profil
    post 'architecte/profil-pro',      to: 'onboarding#create_architecte_profil',       as: :create_architecte_profil

    get  'entrepreneur/invitation',    to: 'onboarding#entrepreneur_invitation',        as: :entrepreneur_invitation
    post 'entrepreneur/invitation',    to: 'onboarding#create_entrepreneur_invitation', as: :create_entrepreneur_invitation

    get  'intermediaire/structure',    to: 'onboarding#intermediaire_structure',        as: :intermediaire_structure
    post 'intermediaire/structure',    to: 'onboarding#create_intermediaire_structure', as: :create_intermediaire_structure
  end

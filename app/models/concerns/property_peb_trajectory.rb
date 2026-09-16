module PropertyPebTrajectory
  extend ActiveSupport::Concern

  PEB_TRAJECTORY = {
    'wallonie' => {
      labels_order: %w[G F E D C B A A+],
      milestones: [
        {
          year: 2033,
          target: 'E',
          description: 'Fin des passoires énergétiques — label minimum E obligatoire',
          priority_works: ['Isolation toiture (R ≥ 4,5 m²K/W)', 'Isolation murs extérieurs', 'Double vitrage performant']
        },
        {
          year: 2040,
          target: 'D',
          description: 'Progression vers label D',
          priority_works: ['Ventilation contrôlée (type C ou D)', 'Châssis à rupture de pont thermique']
        },
        {
          year: 2045,
          target: 'C',
          description: 'Étape intermédiaire vers A 2050',
          priority_works: ['Audit PAE obligatoire', 'Pompe à chaleur ou chauffage haute efficacité']
        },
        {
          year: 2050,
          target: 'A',
          description: 'Objectif final — bâtiment quasi nul énergie (NZEB)',
          priority_works: ['Panneaux photovoltaïques', 'Stockage énergie', 'Gestion intelligente']
        }
      ]
    },
    'flandre' => {
      labels_order: %w[F E D C B A A+],
      milestones: [
        {
          year: 2028,
          target: 'D',
          description: 'Renovatieverplichting — logements loués F/G → label D obligatoire',
          priority_works: ['Isolation toiture (R ≥ 4,0)', 'Isolation sols', 'Double vitrage HR++']
        },
        {
          year: 2030,
          target: 'D',
          description: 'Label D minimum pour tout bien mis en transaction',
          priority_works: ['Ventilation type C/D', 'Châssis performants (Uw ≤ 1,5)']
        },
        {
          year: 2040,
          target: 'C',
          description: 'Progression vers label C',
          priority_works: ['Pompe à chaleur air/eau', 'Isolation murs extérieurs (R ≥ 2,5)']
        },
        {
          year: 2050,
          target: 'A',
          description: 'Objectif final — bijna-energieneutraal gebouw (BENG)',
          priority_works: ['Panneaux solaires + stockage', 'Domotique intelligente']
        }
      ]
    },
    'bruxelles' => {
      labels_order: %w[G F E D C B A A+],
      milestones: [
        {
          year: 2033,
          target: 'E',
          description: 'Fin des passoires F/G — label minimum E obligatoire',
          priority_works: ['Isolation toiture et murs', 'Remplacement châssis simple vitrage']
        },
        {
          year: 2045,
          target: 'D',
          description: 'Progression vers label D obligatoire',
          priority_works: ['Ventilation double flux', 'Pompe à chaleur ou raccordement réseau chaleur']
        },
        {
          year: 2050,
          target: 'C',
          description: 'Objectif final Bruxelles (C+/B/A)',
          priority_works: ['Panneaux photovoltaïques', 'Smart energy management']
        }
      ]
    }
  }.freeze

  # Retourne la trajectoire PEB réglementaire personnalisée pour ce bien.
  # Chaque milestone indique le statut :compliant / :urgent / :upcoming / :future.
  def peb_trajectory
    region_key = region&.downcase
    return nil unless PEB_TRAJECTORY.key?(region_key)

    config       = PEB_TRAJECTORY[region_key]
    current      = peb_certificate_value&.upcase
    labels_order = config[:labels_order]
    current_idx  = current ? (labels_order.index(current) || -1) : nil

    milestones = config[:milestones].map do |m|
      target_idx  = labels_order.index(m[:target]) || 0
      compliant   = current_idx && current_idx >= target_idx
      years_until = m[:year] - Date.current.year

      status = if compliant
                 :compliant
      elsif years_until <= 3
                 :urgent
      elsif years_until <= 10
                 :upcoming
      else
                 :future
               end

      m.merge(status: status, compliant: compliant)
    end

    {
      region:        region_key,
      current_label: current || 'Non renseigné',
      milestones:    milestones
    }
  end
end

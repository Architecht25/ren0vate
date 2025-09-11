# Monitoring de l'usage du stockage
# À utiliser pour suivre quand migrer vers S3

class StorageMonitor
  def self.document_count
    ActiveStorage::Attachment.joins(:blob).count
  end

  def self.total_size_mb
    ActiveStorage::Blob.sum(:byte_size) / 1.megabyte
  end

  def self.total_size_gb
    total_size_mb / 1024.0
  end

  def self.monthly_uploads_count
    ActiveStorage::Attachment.joins(:blob)
      .where(created_at: 1.month.ago..Time.current)
      .count
  end

  def self.should_migrate_to_s3?
    # Migration recommandée si > 20GB ou > 1000 uploads/mois
    total_size_gb > 20 || monthly_uploads_count > 1000
  end

  def self.cloudinary_usage_report
    {
      total_documents: document_count,
      total_size_gb: total_size_gb.round(2),
      monthly_uploads: monthly_uploads_count,
      migration_recommended: should_migrate_to_s3?
    }
  end

  def self.estimated_s3_monthly_cost_usd
    # Calcul approximatif du coût S3
    storage_cost = total_size_gb * 0.023  # $0.023/GB/mois
    # Estimation conservatrice de 10% du stockage en download/mois
    bandwidth_cost = (total_size_gb * 0.1) * 0.09  # $0.09/GB sortie

    (storage_cost + bandwidth_cost).round(2)
  end
end

# Usage en console Rails :
# StorageMonitor.cloudinary_usage_report
# StorageMonitor.estimated_s3_monthly_cost_usd

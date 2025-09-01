# 🛡️ Système de Backup Ren0vate

Ce document décrit le système de sauvegarde complet mis en place après l'incident de perte des utilisateurs en production.

## 📋 **OVERVIEW**

### Types de Backup
1. **Backup Heroku automatique** - Quotidien à 2h
2. **Backup local complet** - Script bash avec archivage
3. **Backup JSON critiques** - Utilisateurs, propriétés, projets
4. **Monitoring et restauration** - Scripts automatisés

## 🔧 **CONFIGURATION INITIALE**

### 1. Backup Heroku Automatique
```bash
# Déjà configuré - vérifie le statut
heroku pg:backups:schedules

# Backup manuel immédiat
heroku pg:backups:capture
```

### 2. Scripts de Backup Local
```bash
# Rendre exécutable
chmod +x bin/backup_production.sh
chmod +x bin/restore_production.sh
chmod +x bin/setup_cron_backup.sh

# Configuration du cron automatique
./bin/setup_cron_backup.sh
```

## 📦 **UTILISATION**

### Backup Manuel Complet
```bash
# Backup complet (BDD + JSON + archivage)
./bin/backup_production.sh
```

### Backup Données Critiques (JSON)
```bash
# Via rake task
heroku run rake backup:critical_data

# En local
rake backup:critical_data
```

### Restauration
```bash
# Restauration complète depuis backup
./bin/restore_production.sh [date_backup]

# Restauration JSON spécifique
heroku run rake backup:restore_critical_data[20250827_143000]
```

## 📁 **STRUCTURE DES BACKUPS**

```
$HOME/backups/ren0vate/
├── db_backup_20250827_143000.dump        # Base complète
├── users_backup_20250827_143000.json     # Utilisateurs seuls
├── properties_backup_20250827_143000.json # Propriétés seules
├── projects_backup_20250827_143000.json  # Projets seuls
└── ren0vate_complete_backup_20250827_143000.tar.gz # Archive
```

## ⏰ **AUTOMATISATION**

### Cron configuré
```bash
# Backup quotidien à 3h
0 3 * * * cd /path/to/ren0vate && ./bin/backup_production.sh >> ~/logs/ren0vate/backup.log 2>&1
```

### Heroku Scheduler
- Backup quotidien à 2h (Europe/Brussels)
- Rétention : 7 jours (plan gratuit)

## 🚨 **PROCÉDURE D'URGENCE**

### En cas de perte de données

1. **Évaluation rapide**
```bash
heroku run rake users:count
```

2. **Backup de l'état actuel**
```bash
heroku pg:backups:capture
```

3. **Restauration depuis le dernier backup**
```bash
./bin/restore_production.sh
```

4. **Vérification**
```bash
heroku run rake users:count
```

### Restauration Utilisateurs Uniquement
```bash
# Si seuls les utilisateurs sont perdus
heroku run rake users:recreate_production
```

## 📊 **MONITORING**

### Vérifications régulières
```bash
# Statut des backups Heroku
heroku pg:backups

# Derniers backups locaux
ls -la ~/backups/ren0vate/ | tail -5

# Logs des backups automatiques
tail -f ~/logs/ren0vate/backup.log
```

### Alertes à surveiller
- Échec de backup automatique Heroku
- Échec de cron local
- Espace disque insuffisant
- Corruption de fichiers

## 🔒 **SÉCURITÉ**

### Chiffrement (recommandé)
```bash
# Chiffrer les backups sensibles
gpg --symmetric --armor backup_file.dump
```

### Stockage externe (recommandé)
- Google Drive / Dropbox pour archivage
- AWS S3 pour stockage professionnel
- Git LFS pour fichiers volumineux

## 🎯 **STRATÉGIE RTO/RPO**

- **RTO (Recovery Time Objective)**: 15 minutes
- **RPO (Recovery Point Objective)**: 24 heures max
- **Données critiques**: < 1 heure (via seeds)

## 📝 **CHECKLIST POST-INCIDENT**

- [x] Backup Heroku automatique configuré
- [x] Scripts de backup/restauration créés
- [x] Automatisation cron configurée
- [x] Documentation complète
- [x] Seeds de récupération d'urgence
- [x] Procédures de test validées

## 🧪 **TESTS RÉGULIERS**

### Test mensuel recommandé
```bash
# 1. Backup de test
./bin/backup_production.sh

# 2. Restauration sur environnement de staging
# (à configurer selon vos besoins)

# 3. Validation des données
heroku run rake users:count
```

## 🆘 **CONTACTS D'URGENCE**

En cas de problème critique :
1. Vérifier les logs : `~/logs/ren0vate/backup.log`
2. Contacter l'administrateur système
3. Utiliser la procédure de récupération d'urgence

---

**Dernière mise à jour**: 27 août 2025
**Version**: 1.0
**Responsable**: Admin Ren0vate

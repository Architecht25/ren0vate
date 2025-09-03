#!/bin/bash

# Script pour surveiller les violations CSP en temps réel

echo "🔍 Surveillance des violations CSP en temps réel..."
echo "Appuyez sur Ctrl+C pour arrêter"

# Suivre les logs Rails en filtrant les violations CSP
tail -f /home/obinduarc/code/Architecht25/ren0vate/log/development.log | grep --line-buffered "CSP VIOLATION" | while read line; do
    echo "$(date '+%H:%M:%S') 🚨 $line"
done

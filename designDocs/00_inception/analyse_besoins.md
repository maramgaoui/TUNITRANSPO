# Analyse des besoins

## 1. Contexte du projet
L’application mobile vise à **faciliter l’utilisation des transports publics** pour les utilisateurs.  
Elle permet de saisir un **point de départ** et un **point d’arrivée**, puis de recevoir les **options de transport disponibles** avec leurs horaires, tarifs et durées.

## 2. Objectifs principaux
- Fournir une **recommandation intelligente** du moyen de transport le plus adapté.
- Informer les utilisateurs des **horaires et tarifs** des différents modes de transport (louages, bus, métro, train).
- Simplifier la planification des trajets et réduire le temps d’attente.

## 3. Utilisateurs cibles
- **Citadins et banlieusards** utilisant régulièrement les transports publics.
- **Touristes ou nouveaux résidents** cherchant à se déplacer efficacement dans la ville.
- **Personnes avec contraintes de temps ou de budget**, souhaitant optimiser leurs trajets.

## 4. Besoins fonctionnels
1. Saisie du point de départ et du point d’arrivée.
2. Affichage de toutes les options de transport disponibles avec :
   - Type de transport (bus, métro, train, louage)
   - Horaires et fréquence
   - Durée estimée du trajet
   - Tarifs
3. Recommandation du **meilleur trajet** selon des critères personnalisables (temps, coût, confort).
4. Possibilité de **mettre à jour les données en temps réel** (retards, indisponibilités, changements d’horaires).
5. Interface intuitive et responsive pour une utilisation mobile fluide.

## 5. Besoins non fonctionnels
- **Performance** : Réponses rapides aux requêtes utilisateur.
- **Sécurité des données** : Protection des informations personnelles et géolocalisation.
- **Disponibilité** : Application stable et accessible 24/7.
- **Scalabilité** : Capacité à gérer un grand nombre d’utilisateurs simultanément.
- **Compatibilité** : Fonctionnement sur Android et iOS.

## 6. Contraintes et hypothèses
- Les données des transports publics sont **accessibles via API publiques ou bases de données locales**.
- Les recommandations se basent sur des **techniques de machine learning** pour optimiser le choix du transport.
- L’application nécessite **une connexion internet** pour obtenir les horaires et mises à jour en temps réel.

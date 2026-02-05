# Sécurité des données

## 1. Introduction
La sécurité des données est essentielle pour protéger **les informations personnelles** et **les données de localisation** des utilisateurs de l'application mobile de transport public.  
Elle vise à garantir **la confidentialité, l'intégrité et la disponibilité** des données.

## 2. Confidentialité
- Chiffrement des données sensibles (mot de passe, email, informations personnelles) **en base de données**  
- Transmission des données via **HTTPS** pour sécuriser les échanges entre le client et le serveur  
- Respect de la **RGPD** et autres réglementations locales sur la protection des données

## 3. Authentification et autorisation
- Authentification des utilisateurs via **JWT (JSON Web Token)**  
- Gestion des rôles et permissions pour accéder uniquement aux ressources autorisées  
- Vérification des droits pour accéder aux **favoris, historique et paramètres** de chaque utilisateur

## 4. Intégrité des données
- Validation et contrôle des données reçues côté serveur  
- Protection contre les **attaques de type injection SQL ou XSS**  
- Sauvegardes régulières de la base de données pour éviter la perte de données

## 5. Disponibilité et continuité
- Surveillance de la disponibilité du serveur et des services critiques  
- Mise en place de **serveurs redondants** et plan de récupération en cas de panne  
- Gestion des pics de trafic grâce à la **scalabilité du backend**

## 6. Bonnes pratiques de sécurité
- Mise à jour régulière des bibliothèques et dépendances  
- Journalisation des accès et actions critiques  
- Formation de l’équipe sur la **cybersécurité et bonnes pratiques**

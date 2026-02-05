# Architecture du système

## 1. Introduction
L'architecture du système décrit l'organisation des composants logiciels et matériels pour l'application mobile intelligente de transport public.

## 2. Architecture générale
L'application adopte une **architecture client-serveur** :

- **Client (Application mobile)** :
  - Interface utilisateur pour saisir le point de départ et d’arrivée.
  - Affichage des résultats et recommandations.
  - Notifications en temps réel.

- **Serveur (Backend)** :
  - Gestion des requêtes et traitements.
  - Communication avec les API des transports publics.
  - Application des algorithmes de machine learning pour la recommandation.
  - Gestion de la base de données (horaires, tarifs, historique utilisateur).

- **Base de données** :
  - Stockage des informations sur les trajets, horaires, tarifs et préférences utilisateurs.
  - Historique des trajets et favoris.

- **API externes** :
  - Sources des données des transports publics (bus, métro, train, louages).
  - Informations en temps réel sur les retards et modifications.

## 3. Diagramme d'architecture (exemple)
# Diagramme d'architecture

```mermaid
graph TD
    Client[Client Mobile]
    Backend[Serveur Backend]
    DB[Base de données]
    API[API Transports Publics]

    Client --> Backend
    Backend --> DB
    Backend --> API

## 4. Technologies proposées
- **Frontend mobile** : React Native 
- **Backend** : Node.js + Express  
- **Base de données** : firebase 
- **Machine Learning** : Python (scikit-learn, TensorFlow)  
- **API** : RESTful API pour communication entre client et serveur

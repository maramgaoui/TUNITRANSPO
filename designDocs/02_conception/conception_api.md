# Conception de l'API

## 1. Introduction
L’API permet la communication entre l’application mobile et le serveur backend pour fournir les informations sur les transports et les recommandations.

## 2. Endpoints principaux

### 2.1 Utilisateur
- `POST /utilisateur/inscription` : créer un compte utilisateur  
- `POST /utilisateur/connexion` : authentification  
- `GET /utilisateur/favoris` : récupérer les trajets favoris  
- `POST /utilisateur/favoris` : ajouter un trajet aux favoris  

### 2.2 Trajet
- `GET /trajet/recherche?depart=X&arrivee=Y` : rechercher les trajets disponibles  
- `GET /trajet/details/{id_trajet}` : récupérer les informations détaillées d’un trajet  

### 2.3 Recommandation
- `GET /recommandation?depart=X&arrivee=Y&criteres=temps,cout` : obtenir le meilleur trajet selon les critères sélectionnés  

## 3. Sécurité
- Authentification via **JWT**  
- Communication sécurisée via **HTTPS**  
- Protection des endpoints critiques (favoris, historique)

## 4. Format des données
- Entrée et sortie en **JSON**  
- Exemple :
```json
{
  "point_depart": "Tunis",
  "point_arrivee": "Ariana",
  "mode_transport": "bus",
  "horaire_depart": "08:00",
  "horaire_arrivee": "08:45",
  "tarif": 1.5,
  "duree_estimee": 45
}

# Modèle de données

## 1. Introduction
Le modèle de données définit la structure des informations stockées dans la base de données pour l'application.

## 2. Entités principales
1. **Utilisateur**
   - `id_utilisateur` (PK)
   - `nom`
   - `email`
   - `mot_de_passe`
   - `favoris` (liste de trajets sauvegardés)

2. **Trajet**
   - `id_trajet` (PK)
   - `point_depart`
   - `point_arrivee`
   - `mode_transport` (bus, métro, train, louage)
   - `horaire_depart`
   - `horaire_arrivee`
   - `tarif`
   - `duree_estimee`

3. **Historique**
   - `id_historique` (PK)
   - `id_utilisateur` (FK)
   - `id_trajet` (FK)
   - `date_utilisation`

4. **Recommandation**
   - `id_recommandation` (PK)
   - `id_trajet` (FK)
   - `score_optimisation` (calculé par le ML)
   - `critere_principal` (temps, coût, confort)

## 3. Relations
- Un **utilisateur** peut avoir plusieurs **trajets favoris**.
- Un **trajet** peut apparaître dans plusieurs **historiques** d’utilisateurs.
- Les **recommandations** sont générées pour chaque trajet en fonction des préférences utilisateurs.

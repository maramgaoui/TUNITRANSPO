# Modèle de recommandation

## 1. Objectif
Le modèle de recommandation permet de **sélectionner le trajet optimal** en combinant plusieurs critères et en utilisant des techniques de Machine Learning.

## 2. Entrées du modèle
- Point de départ et point d’arrivée  
- Horaires des différents moyens de transport  
- Tarifs et durées estimées  
- Préférences de l’utilisateur (temps, coût, confort)  
- Historique des trajets précédents  

## 3. Algorithmes possibles
- **Régression linéaire / multivariée** : prédiction de la durée ou du coût optimal.  
- **Random Forest / Gradient Boosting** : pondération des trajets selon plusieurs critères.  
- **Système de scoring personnalisé** : combine différents critères pour calculer un score global pour chaque trajet.  

## 4. Sorties du modèle
- Classement des trajets du **meilleur au moins optimal**  
- Recommandation affichée à l’utilisateur sur l’interface mobile  
- Possibilité d’ajuster les critères selon les préférences en temps réel

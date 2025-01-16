# Projet_SAS

# 🎮 Analyse des données Twitch et des ventes de jeux vidéo 📊

Ce projet combine des données de streaming **Twitch** et des **ventes de jeux vidéo** pour analyser les tendances de visionnage, les genres populaires, et les relations entre ces deux sources de données.

## 📂 Fichiers de données
- **📁 `data_twitch.csv`** : Contient des données sur les streams Twitch.
- **📁 `data_vgsales.csv`** : Contient des données sur les ventes de jeux vidéo.

## 🛠️ Étapes principales du projet

### 1. 🚀 Importation des données
Les données sont importées à partir de fichiers CSV dans des tables SAS :
- **`twitch`** : Données Twitch 🎥
- **`sales`** : Données des ventes de jeux 🕹️

### 2. 🧹 Préparation des données
- Normalisation des noms des jeux (variable `game_name`).
- Jointure des données Twitch et des ventes sur la base de `game_name`.

### 3. 📈 Analyse univariée
#### 🔢 Variables quantitatives :
- **`current_views`** : Nombre de vues actuelles d'un stream 👀.
- **`total_views_of_this_broadcaster`** : Nombre total de vues d'un streamer 🌟.

Des statistiques descriptives et des histogrammes sont générés pour visualiser la distribution des données.

#### 🎭 Variables qualitatives :
- **Répartition par genre de jeu** : Un diagramme en barre montre les genres les plus populaires.
- Suppression des genres avec moins de 30 occurrences (`Adventure`, `Puzzle`) 🧩.

### 4. 🔗 Analyse bivariée
- **Test ANOVA** : Évaluation des différences de moyennes du nombre de vues (`current_views`) par genre 🎲.
- **Méthode de Tukey** : Identification des genres ayant des moyennes significativement différentes.
- **Corrélation** : Analyse des relations entre variables quantitatives et vues.

### 5. 🌟 Analyse des streamers
- Identification des **5 streamers les plus populaires** dans le genre `Strategy` 🧠.

### 6. 🛒 Analyse des ventes de jeux vidéo
- **📊 Ventes globales** : Somme des ventes par genre.
- **🌍 Ventes moyennes régionales** : Moyennes des ventes en Amérique du Nord, Europe, Japon, et autres régions.
- **📌 Pourcentage des ventes par région** : Distribution des ventes par genre et région.

### 7. 🔍 Régression multiple
Modèle de régression pour examiner les facteurs influençant le nombre de vues :
- Variables explicatives : `total_views_of_this_broadcaster`, `Genre`.
- Résultat : **La variable `total_views_of_this_broadcaster` est significative.**

### 8. 📊 Visualisations
- **Histogrammes** et **diagrammes en barres** pour les distributions des ventes et des genres.
- **Corrélogrammes** pour évaluer les relations entre les variables quantitatives.

## 🖥️ Utilisation
1. Définir le chemin d'accès aux données :
   ```sas
   %let path=/chemin/vers/dossier/data;

## 🖋️ Auteur

Jawhara CHAFI

Mathys GENET

Rémi GOMES MOREIRA

Imane SAHNOUNE


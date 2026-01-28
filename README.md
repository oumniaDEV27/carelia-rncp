# Carelia RNCP – API Parapharmacie (Node.js / Express / PostgreSQL)

Projet RNCP : API backend pour une application de parapharmacie.
Elle permet la gestion des utilisateurs avec rôles (CLIENT / EMPLOYEE / ADMIN), des produits, des réservations (panier multi-produits) ainsi que l’audit des actions sensibles.

---

## Stack technique

* **Node.js** + **Express** (API REST)
* **PostgreSQL** (base de données relationnelle)
* **Docker / Docker Compose** (environnement base de données)
* **JWT** (authentification et autorisation)
* **Swagger** (documentation API)

---

## Prérequis

Avant de commencer, assurez-vous d’avoir installé :

* Node.js (version LTS recommandée)
* Docker Desktop
* Git

---

## Installation

### 1. Cloner le dépôt

```bash
git clone https://github.com/oumniaDEV27/carelia-rncp.git
cd carelia-rncp
```

### 2. Installer les dépendances backend

```bash
cd api
npm install
```

---

## Configuration

Créer un fichier `.env` à partir du fichier fourni :

```bash
cp .env.example .env
```

Variables principales à renseigner :

* `PORT`
* `JWT_SECRET`
* `DB_HOST`
* `DB_USER`
* `DB_PASSWORD`
* `DB_NAME`

⚠️ Le fichier `.env` ne doit jamais être versionné.

---

## Base de données

### 1. Lancer PostgreSQL avec Docker

À la racine du projet :

```bash
docker compose up -d
```

### 2. Initialiser le schéma et les données

Sous Windows (PowerShell) :

```powershell
Get-Content .\database\schema.sql -Raw | docker exec -i carelia_postgres psql -U carelia_user -d carelia
Get-Content .\database\seed.sql -Raw   | docker exec -i carelia_postgres psql -U carelia_user -d carelia
```

### 3. Vérifier les tables

```bash
docker exec -it carelia_postgres psql -U carelia_user -d carelia
\dt
```

---

## Lancer l’API

```bash
cd api
npm run dev
```

L’API est accessible sur :

* [http://localhost:4000](http://localhost:4000)
* Swagger : [http://localhost:4000/docs](http://localhost:4000/docs)

---

## Authentification & rôles

L’application utilise des **JSON Web Tokens (JWT)**.

### Rôles disponibles

* **CLIENT** : consultation des produits, création de réservations
* **EMPLOYEE** : validation/refus des réservations
* **ADMIN** : gestion complète (produits, réservations, suppression)

Les droits sont gérés via des middlewares Express.

---

## Fonctionnalités principales

### Utilisateurs

* Inscription
* Connexion
* Gestion des rôles

### Produits

* Création, modification et suppression (ADMIN)
* Consultation (CLIENT)

### Réservations

* Création d’un panier multi-produits (CLIENT)
* Validation ou refus (EMPLOYEE / ADMIN)
* Suppression (ADMIN)

### Audit

* Journalisation des actions sensibles (création, modification, suppression)

---

## Tests de l’API

Les endpoints peuvent être testés via :

* Swagger : [http://localhost:4000/docs](http://localhost:4000/docs)
* Thunder Client / Postman

---

## Checklist RNCP

* [x] API REST sécurisée
* [x] Authentification JWT
* [x] Gestion des rôles utilisateurs
* [x] CRUD complet
* [x] Base de données relationnelle
* [x] Dockerisation
* [x] Audit des actions
* [x] Documentation technique

---

## Auteur

Projet réalisé dans le cadre du **Titre RNCP – Développeur / Développeuse**.

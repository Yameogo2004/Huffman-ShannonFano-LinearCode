# Projet de Codage de Source et de Canal

### Badges

![MATLAB](https://img.shields.io/badge/MATLAB-R2019b+-orange?logo=mathworks&logoColor=white)
![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-Academic-red)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
![Status](https://img.shields.io/badge/status-stable-brightgreen)
![Commits](https://img.shields.io/github/commit-activity/m/votre-username/Huffman-ShannonFano-LinearCode)
![Code size](https://img.shields.io/github/languages/code-size/votre-username/Huffman-ShannonFano-LinearCode)
![Issues](https://img.shields.io/github/issues/votre-username/Huffman-ShannonFano-LinearCode)
![Last commit](https://img.shields.io/github/last-commit/votre-username/Huffman-ShannonFano-LinearCode)

### Badges personnalisés

![Huffman](https://img.shields.io/badge/Huffman-Optimal-0066cc)
![Shannon-Fano](https://img.shields.io/badge/Shannon--Fano-Approché-cc6600)
![Linear Code](https://img.shields.io/badge/Linear%20Code-C(7,3)-green)
![App Designer](https://img.shields.io/badge/App%20Designer-Interface-purple)

## Compression Huffman / Shannon-Fano & Code Linéaire C(7,3)

---

## Description

Application MATLAB interactive développée avec **App Designer** pour le codage de source et de codage de canal.

### Module 1 : Codage de source (Compression)
- Compression et décompression de fichiers **texte (.txt)** et **images (.jpg, .jpeg, .png)**
- Algorithmes : **Huffman** et **Shannon-Fano**
- Extension d'ordre **N** (codage par blocs de 1 à 10 symboles)
- Affichage  des arbres binaires avec branches colorées
- Calcul des métriques de performance

### Module 2 : Codage de canal (Correction d'erreurs)
- Analyse du **code linéaire binaire C(7,3)**
- Matrice génératrice **G (3x7)** et matrice de contrôle **H (4x7)**
- Distance minimale **dmin = 4** et capacité de correction **t = 1**
- Simulation d'erreurs sur n'importe quelle position (1 à 7)
- Décodage par syndrome et correction automatique

---

## Auteurs

| Nom | Rôle |
|-----|------|
| **Omar Hassan Abdoul-fatah** | Développeur |
| **Yameogo Ariel Barthelemy Wendtoin** | Développeur |

---

## Fonctionnalités détaillées

### Compression/Décompression
| Fonction | Description |
|----------|-------------|
| Chargement | Fichiers .txt, .jpg, .jpeg, .png |
| Algorithmes | Huffman (optimal) / Shannon-Fano (approché) |
| Extension N | Codage par blocs de N symboles (1 à 10) |
| Arbres | Affichage  avec branches 0 et 1 |
| Décompression | Restauration exacte du fichier original |

### Métriques calculées
- Entropie initiale **H(X)**
- Entropie par bloc **H(N)**
- Entropie par symbole
- Longueur moyenne par bloc
- Longueur moyenne par symbole
- Taux de compression
- Efficacité du codage (%)
- Temps d'exécution (secondes)

### Code linéaire C(7,3)
| Fonction | Description |
|----------|-------------|
| Matrice G | Modifiable par l'utilisateur (3x7) |
| Matrice H | Calculée automatiquement |
| Mots-code | Génération des 8 messages possibles |
| Poids | Calcul du poids de Hamming |
| Erreur | Simulation sur position 1 à 7 |
| Syndrome | Calcul et affichage |
| Correction | Décodage et correction automatique |

---

## Prérequis

| Logiciel | Version | Lien |
|----------|---------|------|
| MATLAB | R2019b ou supérieur | [mathworks.com](https://www.mathworks.com) |
| Communications Toolbox | - | Pour huffmandict, huffmanenco, huffmandeco |
| Image Processing Toolbox | - | Pour l'affichage des images |

---

## Installation

### 1. Cloner le dépôt
```bash
git clone https://github.com/votre-username/Huffman-ShannonFano-LinearCode.git
cd Huffman-ShannonFano-LinearCode

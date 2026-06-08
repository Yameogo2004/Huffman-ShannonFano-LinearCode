# Projet de Codage de Source et de Canal

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

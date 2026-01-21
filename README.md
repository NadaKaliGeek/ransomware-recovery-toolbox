# ransomware-recovery-toolbox
Ce projet est une boîte à outils de cybersécurité en C qui simule le comportement d’un ransomware pour analyser le chiffrement de fichiers et proposer des fonctionnalités de déchiffrement et de récupération des données. Il se concentre sur les mécanismes de protection et de restauration des fichiers.


### ⚙️ Initialisation de la toolbox
![Initialisation](Screenshots/wsl_inittoolbox)
![Initialisation](Screenshots/wsl_executable)
Le script met en place l’environnement de travail et génère les exécutables nécessaires s’ils sont absents.

### 📂 Importation de l’archive
![Importation](Screenshots/wsl_import)
Les archives sont ajoutées à la toolbox afin de pouvoir être analysées et traitées.

### 🔓 Restauration de l’archive
![Restauration](Screenshots/wsl_restore)
Le système parcourt l’archive, identifie les fichiers chiffrés et lance le processus de restauration.

### 🔑 Récupération de la clé
![Clé retrouvée](Screenshots/wsl_cletrouve)
La clé est déduite automatiquement à partir des fichiers chiffrés et stockée par le système.

### 📄 Fichier déchiffré
![Fichier déchiffré](Screenshots/wsl_distination)
![Fichier déchiffré](Screenshots/wsl_resultat)
Le contenu du fichier est correctement récupéré et peut être relu normalement.

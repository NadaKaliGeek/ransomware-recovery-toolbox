# Documentation : cipher / decipher / findkey 


## Présentation générale 
Ce projet implémente un système de chiffrement basé sur : 
1. Base64  
2. Chiffrement de Vigenère, mais appliqué sur les indices Base64 
3. Conservation du padding Base64 (=) et des retours à la ligne 

Les outils sont : 
* cipher : applique Vigenère (chiffrement) sur du Base64 
* decipher : applique Vigenère inverse sur du Base64 
* findkey : retrouve automatiquement la clé utilisée en base 64 

---

## 1. cipher — Chiffrement 
🔹 **Objectif**  
Prend un fichier déjà encodé en Base64, et applique Vigenère sur chaque caractère Base64. La clé passée en argument est aussi supposée être en Base64, mais les = sont ignorés. 

### Préparation de la clé
Avant d'utiliser `cipher`, la clé en clair doit être convertie en Base64 :
```bash
echo -n "la clé claire" | base64
```

### Fonctionnement du code 

#### a. Lecture du fichier 
* On ouvre le fichier et on lit tout son contenu dans un buffer dynamique. 
* On ajoute \0 pour faire une chaîne C. 

#### b. Nettoyage de la clé 
```c
if (argv[1][i] != '=') key[j++] = argv[1][i];
```
Les caractères = dans la clé sont supprimés. 
 
#### c. Conversion Base64 
Deux fonctions essentielles :
* `base64_index(c)` → Convertit un caractère Base64 → 0..63 
* `base64_char(idx)` → Convertit 0..63 → caractère Base64

#### d. Vigenère sur Base64 
Pour chaque caractère :
```c
idx_c = (idx_d + idx_k) % 64;
```

Si le caractère est = ou \n : Aucun chiffrement, clé NON avancée. 
 
#### e. Écriture 
Le fichier d'origine est écrasé par la version chiffrée. 

### Utilisation du résultat
Le résultat de `cipher` est du Base64 chiffré. Pour obtenir le binaire brut :
```bash
cat resultat_cipher | base64 -d
```

---

## 2. decipher — Déchiffrement 
🔹 **Objectif**  
Même fonctionnement que cipher, mais on effectue l'opération inverse : 
```c
idx_p = (idx_d - idx_k + 64) % 64;
```
 
### Fonctionnement du code 

#### a. Lecture complète du fichier (comme cipher) 

#### b. Nettoyage de la clé (suppression des =) 

#### c. Déchiffrement 
* Pour chaque caractère Base64 valide → on applique Vigenère inverse
```c
int idx_p = (idx_d - idx_k + 64) % 64;
```
* Les = et \n ne sont jamais modifiés, la clé n'avance pas dessus. 

Le résultat (toujours du Base64) est écrit dans le même fichier.

### Récupération du fichier en clair
Après `decipher`, le résultat est du Base64 déchiffré. Pour obtenir le fichier original :
```bash
cat resultat_decipher | base64 -d
```

Pour les fichiers binaires (images, etc.), rediriger vers un nouveau fichier :
```bash
base64 -d resultat_decipher.png > resultat_final.png
```

---

## 3. findkey — Retrouver la clé 
🔹 **Objectif**  
À partir de : 
* un fichier clair Base64 
* un fichier chiffré Base64 

retrouver : 
* la clé brute (une répétition de la clé réelle) 
* la période minimale de la clé 
* la clé réelle 

### Fonctionnement du code 

#### a. Lecture des deux fichiers en Base64 
* On lit entièrement les deux fichiers. 
* On compare caractère par caractère. 

#### b. Extraction brute des caractères de clé 
Pour chaque position i : 

Si clair64[i] et chiff64[i] sont valides : 
```c
idx_k = (idx_x - idx_c + 64) % 64;
key_raw[kr++] = base64_char(idx_k);
```

Résultat : `key_raw = KKKKKKKKKKKK...` (la clé répétée) 

#### c. Détection de la période réelle 
`find_period()` cherche la plus petite longueur p telle que : 
```
key_raw[i] == key_raw[i % p] pour tout i
```

Exemple : 
```
key_raw = ABCABCABCABC → période = 3 → clé = "ABC"
```

#### d. Sorties : 
* stdout → la clé réelle 
* stderr → la longueur de la clé

---

## Résumé des flux de données

### 🔶 Chiffrement complet
```
[Clé claire] → base64 → [Clé Base64]
[Fichier binaire] → base64 → [Base64 clair] → cipher → [Base64 chiffré] → base64 -d → [Binaire chiffré]
```

### 🔶 Déchiffrement complet
```
[Base64 chiffré] → decipher → [Base64 clair] → base64 -d → [Fichier original]
```

### 🔶 Recherche de clé
```
[clair64] + [chiffré64] → findkey → [clé Base64] → période → [clé finale]
```

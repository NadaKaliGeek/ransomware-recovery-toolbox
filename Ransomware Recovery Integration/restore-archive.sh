#!/bin/bash


source ./check-archive.sh || {
    echo "Erreur : impossible de charger check-archive.sh"
    exit 1
}


# VARIABLES RÉUTILISÉES


wd="$(pwd)/.sh-toolbox"
doc="$1"

archive_select="$ARCHIVE_SELECTED"
attack_ts="$ATTACK_TS"
data_dir="$DATA_DIR" # pwd/temp/data
modified_files="$MODIFIED_FILES"
tmp_extrait="$TMP_DIR" # pwd/temp


# VÉRIFICATIONS

./init-toolbox.sh
./restore-toolbox.sh

if [ -z "$doc" ]; then
    echo "Usage : $0 <dossier_destination>"
    exit 2
fi

if [ ! -d "$doc" ]; then
    mkdir -p "$doc" || {
        echo "Erreur : création du dossier de destination échouée"
        exit 3
    }
fi

# RECHERCHE DES FICHIERS CLAIRS + CLÉ


tmp_key="/tmp/key_restore"

while IFS= read -r fichier_chiffre; do
    [ -f "$fichier_chiffre" ] || continue

    base_name=$(basename "$fichier_chiffre")

    fichier_clair=""
    while IFS= read -r f; do
        [ "$f" = "$fichier_chiffre" ] && continue
        file_ts=$(stat -c "%Y" "$f")
        if [ "$file_ts" -le "$attack_ts" ]; then
            fichier_clair="$f"
        fi
    done < <(find "$data_dir" -type f -name "$base_name")

    [ -z "$fichier_clair" ] && continue

    echo "Fichier chiffré : $fichier_chiffre"
    echo "Fichier clair   : $fichier_clair"

    rm -f "$tmp_key"

    base64 "$fichier_chiffre" > /tmp/fichier_chiffre_base64
    base64 "$fichier_clair"   > /tmp/fichier_clair_base64

    ./findkey /tmp/fichier_clair_base64 /tmp/fichier_chiffre_base64 > "$tmp_key"
    # -s retourne vrai si le fichier existe et que ca taille est superieur a 0
    if [ ! -s "$tmp_key" ]; then
        echo "Erreur : clé non trouvée"
        rm -f "$tmp_key"
        exit 6
    fi

    key=$(tr -d '\n' < "$tmp_key")
    safe_archive=$(echo "$archive_select" | sed 's/[][\.*^$/]/\\&/g')

    if [[ $key =~ ^[[:print:]]+$ ]]; then
        sed -Ei "2,\$ s|^($safe_archive:[^:]*:).*|\1$key:s|" "$wd/archives"
        rm -f "$tmp_key"
        break
    else
        key_name=$(basename "$archive_select" | sed 's/\.tar\.gz$//')
        key_dir="$wd/$key_name"
        mkdir -p "$key_dir"
        mv "$tmp_key" "$key_dir/KEY"
        sed -Ei "2,\$ s|^($safe_archive:[^:]*:).*|\1:f|" "$wd/archives"
        rm -f "$tmp_key"
        break
    fi
done < "$modified_files"

########################################
# RESTAURATION DES FICHIERS
########################################

indice=$(grep "^$archive_select:" "$wd/archives" | cut -d ':' -f4)

if [ "$indice" = "s" ]; then
    cle=$(grep "^$archive_select:" "$wd/archives" | awk -F':' '{print $3}')
else
    key_dir="$wd/$(echo "$archive_select" | sed 's/\.tar\.gz$//')"
    cle=$(cat "$key_dir/KEY")
fi


escaped_tmp=$(printf '%s\n' "$tmp_extrait" | sed 's/[\/&]/\\&/g') # tmp_extrait =pwd/temp


while IFS= read -r f; do
    [ -f "$f" ] || continue


    rel_path=$(echo "$f" | sed -E "s|^$escaped_tmp/?||") # cest pr trouver le chemin relatif (chemin absolue - pwd/temp)

    dest_file="$doc/$rel_path"
    dest_dir="$(dirname "$dest_file")"

    mkdir -p "$dest_dir"

    if [ -f "$dest_file" ]; then
        read -p "Le fichier $dest_file existe. Écraser ? (o/n) " rep
        [ "$rep" != "o" ] && continue
    fi

    echo "Restauration de $dest_file"

    base64 "$f" > /tmp/fichier_chiffre_base64
    
    
    if ! ./decipher "$cle" /tmp/fichier_chiffre_base64 1>/dev/null; then
        echo "Échec de restauration : $f"
        continue
    fi

   cp /tmp/fichier_chiffre_base64 "$dest_file"

done < "$modified_files"

########################################
# NETTOYAGE
########################################

rm -f /tmp/fichier_chiffre_base64 /tmp/fichier_clair_base64 /tmp/key_restore
rm -f "$modified_files"
rm -r "$tmp_extrait"

echo "Restauration terminée."
exit 0
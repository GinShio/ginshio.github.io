#!/usr/bin/env bash

ROOT_DIR=$(readlink --canonicalize $(dirname $0)/..)

source $ROOT_DIR/.info
echo ${PERSONAL_EMAIL:?Missing personal email.} >/dev/null
echo ${WORK_EMAIL:?Missing work email.} >/dev/null
echo ${WORK_ORGNAIZATION:?Missing work orgnaization.} >/dev/null
echo ${FILENAME:-ssh-in-$(date "+%Y")} >/dev/null
if ! [ -e $ROOT_DIR/.kfile ]
then echo ${KFILE_NOT_EXIST:?Password file not exists.} >/dev/null
fi

cd $(mktemp -d)

declare -a key_items=(
  "${WORK_ORGNAIZATION}-pri-ssh"
  "${WORK_ORGNAIZATION}-pri-git"
  "${WORK_ORGNAIZATION}-pub-git"
  "personal-git"
  "personal-ssh"
)

for item in ${key_items[@]}; do
    if [[ "$item" =~ "$WORK_ORGNAIZATION" ]]
    then comment="$item-${WORK_EMAIL}"
    elif [[ "$item" =~ "personal" ]]
    then comment="$item-${PERSONAL_EMAIL}"
    else comment="$item"
    fi
    ssh-keygen -C "$comment" -t ed25519 -f "$PWD/$item" -N ""
done
chmod a-w *
tar -cf - * |zstd -z -19 --ultra --quiet -o $FILENAME.tar.zst
openssl enc -aes-256-cbc -e -a -kfile $ROOT_DIR/.kfile -salt -pbkdf2 -iter 100000 -in $FILENAME.tar.zst -out $FILENAME.tar.zst.ssl
rsync --remove-source-files $FILENAME.tar.zst.ssl $ROOT_DIR/assets/key

#!/bin/bash

# usage
usage() {
    echo "usage: $0 -u username [-p password] [-g group]"
    echo "example: $0 -u alice -p 123456 -g sudo"
    exit 1
}

# default values
USERNAME=""
PASSWORD="wolaila"
USERGROUP="sudo"

# parse args
while getopts "u:p:g:" opt; do
    case "$opt" in
        u) USERNAME="$OPTARG" ;;
        p) PASSWORD="$OPTARG" ;;
        g) USERGROUP="$OPTARG" ;;
        *) usage ;;
    esac
done

if [[ -z "$USERNAME" ]]; then
    echo "error: username is required"
    usage
fi

# check if user already exists
if id "$USERNAME" &>/dev/null; then
    echo "user $USERNAME already exists"
    exit 1
fi

# create user with home directory and group
useradd -m -G "$USERGROUP" "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

# ensure default shell is bash
chsh -s /bin/bash "$USERNAME"

# ensure .profile sources .bashrc
PROFILE_FILE="/home/$USERNAME/.profile"
if ! grep -q 'source ~/.bashrc' "$PROFILE_FILE"; then
    echo "" >> "$PROFILE_FILE"
    echo "if [ -f ~/.bashrc ]; then" >> "$PROFILE_FILE"
    echo "    . ~/.bashrc" >> "$PROFILE_FILE"
    echo "fi" >> "$PROFILE_FILE"
fi

chown $USERNAME:$USERNAME "$PROFILE_FILE"

# copy and fix shell config
cp /etc/skel/.bashrc /home/$USERNAME/
cp /etc/skel/.profile /home/$USERNAME/
chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc /home/$USERNAME/.profile

# ensure PS1 is properly set
echo "export PS1='\\u@\\h:\\w\\$ '" >> /home/$USERNAME/.bashrc
chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc

echo "user $USERNAME created with password '$PASSWORD' and added to group '$USERGROUP'"

# colorful
BASHRC_FILE="/home/$USERNAME/.bashrc"

# 彩色提示符设置
cat << 'EOF' >> "$BASHRC_FILE"

# personal color prompt
PS1='\[\e[1;32m\]\u\[\e[0m\]@\[\e[1;34m\]\h\[\e[0m\]:\[\e[1;33m\]\w\[\e[0m\]\$ '
EOF

chown "$USERNAME:$USERNAME" "$BASHRC_FILE"



# relocate
PROFILE_FILE="/home/$USERNAME/.bash_profile"

cat << 'EOF' > "$PROFILE_FILE"
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
EOF

chown "$USERNAME:$USERNAME" "$PROFILE_FILE"


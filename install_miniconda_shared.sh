#!/bin/bash
set -e

INSTALL_DIR="/opt/miniconda3"

echo "[1/7] Setting ownership and basic permissions..."
sudo chown -R root:root "$INSTALL_DIR"
sudo chmod -R go-w "$INSTALL_DIR"

echo "[2/7] Restricting write access to base environment only (not the entire install)..."
# Only lock down site-packages and environments to prevent modification
for sp_dir in "$INSTALL_DIR"/lib/python*/site-packages; do
  sudo chmod -R a-w "$sp_dir"
done
sudo chmod -R a-w "$INSTALL_DIR/envs"
sudo chmod -R a-w "$INSTALL_DIR/pkgs"

echo "[3/7] Disabling auto activation of base environment..."
sudo "$INSTALL_DIR/bin/conda" config --system --set auto_activate_base false

echo "[4/7] Creating environment profile script in /etc/profile.d..."
sudo tee /etc/profile.d/miniconda3.sh > /dev/null <<'EOF'
export PATH=/opt/miniconda3/bin:$PATH
export CONDA_ENVS_PATH=$HOME/.conda/envs
export CONDA_PKGS_DIRS=$HOME/.conda/pkgs
export PIP_DISABLE_PIP_VERSION_CHECK=1
. /opt/miniconda3/etc/profile.d/conda.sh
EOF
sudo chmod +x /etc/profile.d/miniconda3.sh

echo "[5/7] Creating default .condarc in /etc/skel..."
sudo mkdir -p /etc/skel/.conda/envs
sudo tee /etc/skel/.condarc > /dev/null <<'EOF'
envs_dirs:
  - $HOME/.conda/envs
pkgs_dirs:
  - $HOME/.conda/pkgs
EOF

echo "[6/7] Applying .condarc configuration for all existing users..."
for userdir in /home/*; do
    [ -d "$userdir" ] || continue
    username=$(basename "$userdir")
    sudo mkdir -p "$userdir/.conda/envs"
    sudo mkdir -p "$userdir/.conda/pkgs"
    sudo tee "$userdir/.condarc" > /dev/null <<EOF
envs_dirs:
  - /home/$username/.conda/envs
pkgs_dirs:
  - /home/$username/.conda/pkgs
EOF
    sudo chown -R "$username:$username" "$userdir/.conda" "$userdir/.condarc"

    # Optional: ensure ~/.bashrc sources conda
    if ! grep -q 'conda.sh' "$userdir/.bashrc"; then
      echo ". /opt/miniconda3/etc/profile.d/conda.sh" | sudo tee -a "$userdir/.bashrc" > /dev/null
    fi
done

echo "[7/7] Creating wrapper scripts for conda and pip to block base installs..."

# Conda wrapper
sudo tee /usr/local/bin/conda > /dev/null <<'EOF'
#!/bin/bash
if [[ "$*" == install* && "$*" != *"--name"* && "$*" != *"--prefix"* ]]; then
  echo "ERROR: Installing into base environment is not allowed. Use a named environment."
  exit 1
fi
exec /opt/miniconda3/bin/conda "$@"
EOF
sudo chmod +x /usr/local/bin/conda

# Pip wrapper
sudo tee /usr/local/bin/pip > /dev/null <<'EOF'
#!/bin/bash
ENV_PREFIX=$(python3 -c "import sys; print(sys.prefix)")
if [[ "$ENV_PREFIX" == "/opt/miniconda3" ]]; then
  echo "ERROR: Installing into base environment with pip is not allowed."
  exit 1
fi
exec /opt/miniconda3/bin/pip "$@"
EOF
sudo chmod +x /usr/local/bin/pip

echo "Done. Users should re-login or run 'source /etc/profile.d/miniconda3.sh'."


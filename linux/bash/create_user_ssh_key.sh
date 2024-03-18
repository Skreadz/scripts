$password="#ERTYsdfg098ituserissecure"

useradd ituser
usermod --shell /bin/bash ituser
usermod -aG sudo ituser

(passwd ituser <<EOF
$password
$password
EOF
)

mkdir -p /home/ituser/.ssh/
echo "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOE8vMc9aNP8wv8e7/s8NyeW2Kol3h6xPlY5jRPEjUjGtdMLegNy+PenTvo1mAHV+3O2D0nf2IF+84OWvMamy9k= ituser" > /home/ituser/.ssh/authorized_keys
chown -R ituser:ituser /home/ituser
chmod 644 /home/ituser/.ssh/authorized_keys

echo "ituser  ALL=(ALL)  NOPASSWD: ALL" > /etc/sudoers.d/ituser
chmod 644 /etc/sudoers.d/ituser




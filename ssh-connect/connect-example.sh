#!/bin/bash

SERVER_IP="47.104.159.142"
USER="root"
KEY_FILE="$HOME/.ssh/id_ed25519"

echo "=== SSH 连接示例脚本 ==="
echo "服务器: $SERVER_IP"
echo "用户: $USER"
echo "密钥文件: $KEY_FILE"
echo ""

if [ ! -f "$KEY_FILE" ]; then
    echo "错误: 密钥文件不存在，正在生成..."
    ssh-keygen -t ed25519 -f "$KEY_FILE" -N '' -C 'trae@local'
fi

echo "公钥内容:"
cat "${KEY_FILE}.pub"
echo ""

echo "请将上述公钥添加到服务器的 ~/.ssh/authorized_keys"
echo ""

echo "配置 SSH config..."
mkdir -p "$HOME/.ssh"
cat > "$HOME/.ssh/config" << EOF
Host $SERVER_IP
    HostName $SERVER_IP
    User $USER
    IdentityFile $KEY_FILE
    ProxyCommand nc -X connect -x 127.0.0.1:18080 %h %p
    StrictHostKeyChecking no
EOF

echo "连接测试..."
ssh -i "$KEY_FILE" -o ConnectTimeout=15 "$USER@$SERVER_IP" "echo '连接成功!' && hostname && whoami && date"

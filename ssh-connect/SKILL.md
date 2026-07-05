---
name: ssh-connect
description: 在 Trae Work 上安全连接云服务器的完整指南和操作流程
version: 1.0.0
---

# SSH 云服务器连接技能

## 概述

本技能提供在 Trae Work 环境下安全连接云服务器的完整操作流程，涵盖密钥管理、网络配置、代理设置和故障排查。

## 连接流程总结

### 阶段一：环境准备

1. **检查本地 SSH 密钥**
   ```bash
   ls -la ~/.ssh/
   ```

2. **生成 Ed25519 密钥对（推荐）**
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N '' -C 'trae@local'
   ```

3. **获取公钥内容**
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

### 阶段二：服务器端配置

1. **通过云服务商网页终端登录服务器**

2. **创建 .ssh 目录并添加公钥**
   ```bash
   mkdir -p ~/.ssh
   echo "<公钥内容>" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   chmod 700 ~/.ssh
   ```

3. **检查 SSH 服务状态**
   ```bash
   systemctl status sshd
   systemctl start sshd
   systemctl enable sshd
   ```

4. **开放防火墙端口**
   ```bash
   ufw allow 22/tcp
   ```

5. **在云服务商安全组中开放端口 22**

### 阶段三：网络配置（Trae Work 特有）

1. **检查网络环境**
   ```bash
   ip addr
   env | grep -i proxy
   ```

2. **配置 SSH 代理（如使用代理环境）**
   ```bash
   cat > ~/.ssh/config << 'EOF'
   Host <服务器IP>
       HostName <服务器IP>
       User <用户名>
       IdentityFile ~/.ssh/id_ed25519
       ProxyCommand nc -X connect -x 127.0.0.1:18080 %h %p
       StrictHostKeyChecking no
   EOF
   ```

### 阶段四：连接验证

```bash
ssh -i ~/.ssh/id_ed25519 <用户名>@<服务器IP> "echo '连接成功' && hostname && whoami"
```

## 常见问题排查

### 问题 1：连接超时

```bash
# 检查端口开放状态
timeout 3 bash -c "echo > /dev/tcp/<服务器IP>/22" && echo "端口开放" || echo "端口关闭"

# 检查 HTTP 连通性
curl -s -o /dev/null -w "%{http_code}" http://<服务器IP>
```

**解决方案**：在云服务商安全组中开放端口 22

### 问题 2：权限拒绝（Permission denied）

```bash
# 检查服务器端 authorized_keys 权限
ls -la ~/.ssh/authorized_keys

# 检查 SELinux（如适用）
ls -lZ ~/.ssh/authorized_keys
```

**解决方案**：确保 `authorized_keys` 权限为 600，`.ssh` 目录权限为 700

### 问题 3：代理环境下无法连接

```bash
# 检查代理配置
env | grep -i proxy

# 使用 nc 命令测试代理连通性
nc -X connect -x 127.0.0.1:18080 <服务器IP> 22
```

**解决方案**：配置 `~/.ssh/config` 使用 ProxyCommand

## 安全最佳实践

1. **使用 Ed25519 密钥**：比 RSA 更安全、更快
2. **禁用密码认证**：在 `/etc/ssh/sshd_config` 中设置 `PasswordAuthentication no`
3. **限制 root 登录**：设置 `PermitRootLogin without-password`
4. **使用非标准端口**：修改 SSH 端口并在安全组中相应配置
5. **定期轮换密钥**：定期生成新密钥对
6. **使用 fail2ban**：防止暴力破解

## 快捷命令参考

### 生成新密钥
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_<别名> -N ''
```

### 复制公钥到服务器
```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub <用户名>@<服务器IP>
```

### SSH 连接
```bash
ssh -i ~/.ssh/id_ed25519 <用户名>@<服务器IP>
```

### SSH 配置示例
```bash
cat > ~/.ssh/config << 'EOF'
Host myserver
    HostName 47.104.159.142
    User root
    IdentityFile ~/.ssh/id_ed25519
    Port 22
    StrictHostKeyChecking accept-new
EOF
```

## 注意事项

- Trae Work 环境可能使用代理，需要配置 `ProxyCommand`
- 云服务器安全组配置生效可能需要 1-5 分钟
- 首次连接时会提示确认主机指纹，使用 `StrictHostKeyChecking no` 可跳过
- 生产环境应使用 `StrictHostKeyChecking accept-new` 而非 `no`

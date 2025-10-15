# Windows Admin Creator

Script PowerShell para criar usuários administradores locais no Windows e enviar as credenciais por email.

## 📋 Pré-requisitos

- Windows PowerShell 5.1 ou superior
- Executar como Administrador
- Acesso à internet para envio de emails

## 🚀 Como usar

### 1. Configuração inicial

1. Copie o arquivo `.env.example` para `.env`:

   ```powershell
   Copy-Item .env.example .env
   ```
2. Edite o arquivo `.env` com suas configurações de email:

   - `EMAIL_REMETENTE`: Seu email corporativo
   - `SENHA_REMETENTE`: Senha do email
   - `EMAIL_DESTINATARIO`: Email que receberá as credenciais
   - `EMAIL_DESTINATARIO2`: Email secundário (opcional)
   - `SMTP_SERVER`: Servidor SMTP da sua empresa
   - `SMTP_PORT`: Porta SMTP (geralmente 587)

### 2. Executando o script

1. Abra PowerShell como **Administrador**
2. Navegue até a pasta do script
3. Execute: `.\CriarAdmin.ps1`
4. Siga as instruções na tela

## 🔒 Segurança

- **NUNCA** compartilhe o arquivo `.env`
- O arquivo `.env` está configurado no `.gitignore` para evitar versionamento acidental
- Use senhas de aplicativo quando possível
- As senhas geradas seguem o padrão: `makino-XXXXX` (5 dígitos aleatórios)

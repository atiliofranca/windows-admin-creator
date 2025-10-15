# Windows Admin Creator

Script PowerShell para criar usuários administradores locais no Windows e enviar as credenciais por email.

## 📋 Pré-requisitos

- Windows PowerShell 5.1 ou superior
- Executar como Administrador
- Acesso à internet para envio de emails

## 🚀 Como usar

### 1. Configuração inicial (apenas na primeira vez)

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

1. **Abra PowerShell como Administrador**
2. **Navegue até a pasta do script:**
   ```powershell
   cd "c:\windows-admin-creator"
   ```
3. **Execute o script:**
   ```powershell
   .\CriarAdmin.ps1
   ```
4. **Se necessário, ajuste a política de execução (ver Solução de Problemas)**
5. **Siga as instruções na tela**
   - Informe o número para o usuário (ex: 001, 123)
   - Informe o nome do funcionário que está usando o PC
   - Após o email ser enviado, escolha se quer alterar sua conta para Padrão

## 🔧 Solução de Problemas

### ❌ Erro: "a execução de scripts foi desabilitada neste sistema"

**Solução:** Execute este comando no PowerShell como Administrador:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
```

> Este comando afeta APENAS a sessão atual. Quando fechar o PowerShell, volta ao normal.

### ❌ Erro: "Arquivo .env não encontrado"

**Solução:**

1. Certifique-se de estar na pasta correta do script
2. Copie o arquivo `.env.example` para `.env`:
   ```powershell
   Copy-Item .env.example .env
   ```
3. Configure o arquivo `.env` com suas credenciais

### ❌ Erro no envio de email

**Solução:**

1. Verifique as configurações SMTP no arquivo `.env`
2. Teste se o servidor SMTP está acessível
3. Verifique se a senha do email está correta
4. Para Gmail/Outlook, use senhas de aplicativo

### ❌ Erro: "O usuário já existe"

**Solução:** O usuário com esse número já foi criado anteriormente. Use um número diferente.

## ⚙️ Funcionalidades do Script

### 🔄 Alteração de Tipo de Conta

Após criar o usuário administrador e enviar o email, o script oferece uma opção adicional:

**Pergunta:** "Deseja alterar a conta atual de Administrador para Padrão?"

- ✅ **Se responder S**: A conta atual será alterada de Administrador para Padrão
- ❌ **Se responder N**: A conta atual permanece como Administrador
- ℹ️ **Se a conta já for Padrão**: Mostra mensagem informativa

**Benefícios:**

- Melhora a segurança do sistema (princípio do menor privilégio)
- Evita o uso desnecessário de contas administrativas no dia a dia
- Automatiza processo que seria feito manualmente no Painel de Controle

**Processo manual equivalente:**
`Painel de Controle → Contas de Usuário → Gerenciar Contas → Alterar uma conta → Alterar Tipo de Conta`

> ⚠️ **Importante**: A alteração de tipo de conta terá efeito após fazer logout/login

## 🔒 Segurança

- **NUNCA** compartilhe o arquivo `.env`
- O arquivo `.env` está configurado no `.gitignore` para evitar versionamento acidental
- Use senhas de aplicativo quando possível
- As senhas geradas seguem o padrão: `makino-XXXXX` (5 dígitos aleatórios)

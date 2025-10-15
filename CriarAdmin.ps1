# --- Inicio do Script ---

# Script para criar um novo usuario administrador e enviar a senha por e-mail.

# --- VERIFICACAO DE POLITICA DE EXECUCAO ---
function Check-ExecutionPolicy {
    $currentPolicy = Get-ExecutionPolicy
    $restrictivePolicies = @("Restricted", "AllSigned")
    
    if ($currentPolicy -in $restrictivePolicies) {
        Write-Host "==========================================" -ForegroundColor Yellow
        Write-Host "AVISO: Politica de Execucao Restritiva" -ForegroundColor Red
        Write-Host "==========================================" -ForegroundColor Yellow
        Write-Host "Politica atual: $currentPolicy" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Para executar este script, execute o comando abaixo:" -ForegroundColor White
        Write-Host "Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process" -ForegroundColor Green
        Write-Host ""
        Write-Host "Este comando:" -ForegroundColor White
        Write-Host "- Afeta APENAS esta sessao do PowerShell" -ForegroundColor White
        Write-Host "- E temporario e seguro" -ForegroundColor White
        Write-Host "- Volta ao normal quando fechar o PowerShell" -ForegroundColor White
        Write-Host "==========================================" -ForegroundColor Yellow
        
        $resposta = Read-Host "Deseja que eu tente alterar automaticamente? (S/N)"
        if ($resposta -match "^[SsYy]") {
            try {
                Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
                Write-Host "Politica alterada com sucesso!" -ForegroundColor Green
                Write-Host "Continuando execucao do script..." -ForegroundColor Green
                Start-Sleep -Seconds 2
            } catch {
                Write-Host "Erro ao alterar politica: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Execute manualmente o comando mostrado acima." -ForegroundColor Yellow
                Read-Host "Pressione Enter para sair"
                exit
            }
        } else {
            Write-Host "Execute o comando mostrado acima e tente novamente." -ForegroundColor Yellow
            Read-Host "Pressione Enter para sair"
            exit
        }
    }
}

# Executa a verificacao de politica
Check-ExecutionPolicy

# --- VERIFICACAO DE PRIVILEGIOS DE ADMINISTRADOR ---
function Check-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "==========================================" -ForegroundColor Red
        Write-Host "ERRO: Privilegios Insuficientes" -ForegroundColor Red
        Write-Host "==========================================" -ForegroundColor Red
        Write-Host "Este script precisa ser executado como ADMINISTRADOR." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Como executar como Administrador:" -ForegroundColor White
        Write-Host "1. Feche este PowerShell" -ForegroundColor White
        Write-Host "2. Clique com botao direito no PowerShell" -ForegroundColor White
        Write-Host "3. Selecione 'Executar como administrador'" -ForegroundColor White
        Write-Host "4. Execute o script novamente" -ForegroundColor White
        Write-Host "==========================================" -ForegroundColor Red
        Read-Host "Pressione Enter para sair"
        exit
    }
}

# Executa a verificacao de privilegios
Check-AdminRights

# --- FUNCAO PARA CARREGAR CONFIGURACOES DO ARQUIVO .ENV ---
function Load-EnvFile {
    param(
        [string]$FilePath = ".\.env"
    )
    
    if (Test-Path $FilePath) {
        $envVars = @{}
        Get-Content $FilePath | ForEach-Object {
            $line = $_.Trim()
            # Ignora linhas vazias e comentários
            if ($line -and !$line.StartsWith("#")) {
                $key, $value = $line -split '=', 2
                if ($key -and $value) {
                    $envVars[$key.Trim()] = $value.Trim()
                }
            }
        }
        return $envVars
    } else {
        throw "Arquivo .env não encontrado em: $FilePath"
    }
}

# --- CARREGA CONFIGURACOES DO ARQUIVO .ENV ---
try {
    $envConfig = Load-EnvFile
    $emailRemetente = $envConfig["EMAIL_REMETENTE"]
    $senhaRemetente = $envConfig["SENHA_REMETENTE"]
    $emailDestinatario = $envConfig["EMAIL_DESTINATARIO"]
    $emailDestinatario2 = $envConfig["EMAIL_DESTINATARIO2"]
    $smtpServer = $envConfig["SMTP_SERVER"]
    $smtpPort = [int]$envConfig["SMTP_PORT"]
    
    # Verifica se todas as configurações necessárias foram carregadas
    if (-not ($emailRemetente -and $senhaRemetente -and $emailDestinatario -and $smtpServer -and $smtpPort)) {
        throw "Algumas configurações obrigatórias estão faltando no arquivo .env"
    }
} catch {
    Write-Host "ERRO ao carregar configurações do arquivo .env: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Certifique-se de que o arquivo .env existe e contém todas as configurações necessárias." -ForegroundColor Yellow
    Read-Host "Pressione Enter para fechar a janela."
    exit
}

# -----------------------------------------------------------------

# Bloco principal com tratamento de erros.
try {
    # Solicita ao usuario o numero para compor o nome de usuario
    $userNumber = Read-Host "Digite o numero para o nome de usuario (ex: 001, 123)"
    if ([string]::IsNullOrWhiteSpace($userNumber)) {
        throw "Nenhum numero foi fornecido."
    }
    
    # Pergunta o nome do funcionario
    $nomeFuncionario = Read-Host "Digite o nome do(a) funcionario(a) que esta usando esse PC no momento da criacao do usuario admin"

    $username = "admin-$userNumber"

    # Gera a parte aleatoria da senha (4 caracteres numericos)
    $randomChars = -join ((48..57) | Get-Random -Count 5 | ForEach-Object { [char]$_ })
    $password = "makino-$randomChars"
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force

    # Verifica se o usuario ja existe
    if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
        throw "O usuario '$username' ja existe."
    }

    # Pega a data e hora atual
    $dataCriacao = (Get-Date).ToString('dd/MM/yyyy HH:mm:ss')

    # Cria o novo usuario local e o adiciona ao grupo de Administradores
    Write-Host "Passo 1/2: Criando e configurando o usuario '$username'..." -ForegroundColor Cyan
    New-LocalUser -Name $username -Password $securePassword -FullName $username -Description "Conta de administrador." -PasswordNeverExpires 
    Add-LocalGroupMember -Group "Administradores" -Member $username
    
    # --- Secao de Envio de E-mail ---
    Write-Host "Passo 2/2: Enviando a senha por e-mail..." -ForegroundColor Cyan
    
    # Cria o objeto de credencial a partir das variaveis definidas acima
    $secureSenhaRemetente = ConvertTo-SecureString -String $senhaRemetente -AsPlainText -Force
    $credencial = New-Object System.Management.Automation.PSCredential($emailRemetente, $secureSenhaRemetente)

    # Define o assunto do e-mail usando o nome de usuario gerado
    $emailAssunto = "Senha do usuario $username"

    # Monta o corpo do e-mail com as novas informacoes
    $emailCorpo = @"
Funcionario(a) que esta usando esse PC no momento da criacao do usuario Admin: $nomeFuncionario

Nome de Usuario: $username
Senha Gerada: $password
Data de criacao do usuario admin: $dataCriacao

Guarde esta senha em um local seguro.
"@
    
    # Agrupa os destinatarios
    $destinatarios = @($emailDestinatario, $emailDestinatario2)

    # Tenta enviar o e-mail
    Send-MailMessage -From $emailRemetente -To $destinatarios -Subject $emailAssunto -Body $emailCorpo -SmtpServer $smtpServer -Port $smtpPort -UseSsl -Credential $credencial
        
    Write-Host "--------------------------------------------------" -ForegroundColor Yellow
    Write-Host "PROCESSO CONCLUIDO COM SUCESSO!" -ForegroundColor Green
    Write-Host "Usuario '$username' foi criado e a senha foi enviada para $($destinatarios -join ', ')."
    Write-Host "Assunto do e-mail: '$emailAssunto'"
    Write-Host "--------------------------------------------------" -ForegroundColor Yellow

} catch {
    # Captura e exibe erros
    Write-Host "--------------------------------------------------" -ForegroundColor Red
    Write-Host "OCORREU UM ERRO!" -ForegroundColor Red
    Write-Host "Mensagem: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Verifique as configuracoes de e-mail no script ou se ele foi executado como Administrador." -ForegroundColor Yellow
    # Fallback: Se o envio do e-mail falhar, mostra a senha na tela para nao perde-la.
    if ($password) {
        Write-Host "O usuario PODE TER SIDO CRIADO. Para nao perder o acesso, a senha gerada e:" -ForegroundColor Yellow
        Write-Host "   Senha: $password"
    }
    Write-Host "--------------------------------------------------" -ForegroundColor Red
}

# Pausa no final do script
Read-Host "Pressione Enter para fechar a janela."
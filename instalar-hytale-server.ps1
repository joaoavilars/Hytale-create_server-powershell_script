# Script de Instalação e Inicialização do Servidor Hytale
# Autor: Script Automatizado
# Data: $(Get-Date -Format "yyyy-MM-dd")

param(
    [string]$ServerPath = ".\hytale-server",
    [string]$DownloadPath = ".\hytale-server-download",
    [string]$Patchline = "release",
    [switch]$SkipDownload = $false,
    [switch]$SkipInstall = $false
)

# Configurações
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$DownloaderZip = ".\downloader.zip"
$ExtractPath = ".\downloader-extracted"
$LogFile = ".\install-log.txt"

# Função para logging
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogFile -Value $LogMessage
}

# Função para verificar se um comando existe
function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Verificar se está executando como Administrador (se necessário)
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Função para encerrar processos que possam estar usando arquivos
function Stop-ProcessesUsingPath {
    param([string]$Path)
    
    try {
        # Lista de nomes de processos relacionados ao downloader
        $processNames = @("hytale-downloader", "downloader", "hytale")
        
        # Procurar processos por nome
        foreach ($procName in $processNames) {
            $procs = Get-Process -Name "*$procName*" -ErrorAction SilentlyContinue
            foreach ($proc in $procs) {
                Write-Log "Encerrando processo relacionado: $($proc.ProcessName) (PID: $($proc.Id))" "INFO"
                try {
                    Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                    Start-Sleep -Milliseconds 500
                } catch {
                    Write-Log "AVISO: Não foi possível encerrar processo $($proc.ProcessName): $_" "WARNING"
                }
            }
        }
        
        # Procurar processos que possam estar usando arquivos na pasta
        try {
            $processes = Get-Process | Where-Object {
                try {
                    $procPath = $_.Path
                    $procPath -like "$Path*" -or 
                    (Test-Path $procPath) -and (Split-Path (Split-Path $procPath) -Leaf) -eq (Split-Path $Path -Leaf)
                } catch {
                    $false
                }
            }
            
            foreach ($proc in $processes) {
                Write-Log "Encerrando processo que pode estar bloqueando arquivos: $($proc.ProcessName) (PID: $($proc.Id))" "INFO"
                try {
                    Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                    Start-Sleep -Milliseconds 500
                } catch {
                    Write-Log "AVISO: Não foi possível encerrar processo $($proc.ProcessName): $_" "WARNING"
                }
            }
        } catch {
            # Ignorar erros ao verificar processos
        }
        
        # Aguardar um pouco para os processos encerrarem
        Start-Sleep -Seconds 1
    } catch {
        Write-Log "AVISO ao verificar processos: $_" "WARNING"
    }
}

# Função para validar arquivos do servidor
function Test-ServerFiles {
    param([string]$ServerPath)
    
    $errors = @()
    $warnings = @()
    $requiredDirs = @()
    
    # Arquivos e diretórios comuns que devem existir em um servidor Hytale
    # (ajustar conforme necessário baseado na estrutura real)
    $requiredDirs = @(
        "bin",
        "config",
        "logs"
    )
    
    Write-Log "Validando estrutura de arquivos do servidor..." "INFO"
    
    # Verificar se o diretório existe
    if (-not (Test-Path $ServerPath)) {
        $errors += "Diretório do servidor não existe: $ServerPath"
        return @{ Valid = $false; Errors = $errors; Warnings = $warnings }
    }
    
    # Verificar se há arquivos no diretório
    $allFiles = Get-ChildItem -Path $ServerPath -Recurse -File -ErrorAction SilentlyContinue
    if ($allFiles.Count -eq 0) {
        $errors += "Nenhum arquivo encontrado no diretório do servidor"
        return @{ Valid = $false; Errors = $errors; Warnings = $warnings }
    }
    
    Write-Log "Total de arquivos encontrados: $($allFiles.Count)" "INFO"
    
    # Verificar arquivos JAR (essenciais para servidor Java)
    $jarFiles = $allFiles | Where-Object { $_.Extension -eq ".jar" }
    if ($jarFiles.Count -eq 0) {
        $errors += "Nenhum arquivo JAR encontrado (necessário para servidor Java)"
    } else {
        Write-Log "Arquivos JAR encontrados: $($jarFiles.Count)" "INFO"
        foreach ($jar in $jarFiles) {
            Write-Log "  - $($jar.Name) ($([math]::Round($jar.Length / 1MB, 2)) MB)" "INFO"
        }
    }
    
    # Verificar diretórios importantes
    foreach ($dir in $requiredDirs) {
        $dirPath = Join-Path $ServerPath $dir
        if (Test-Path $dirPath) {
            Write-Log "Diretório encontrado: $dir" "INFO"
        } else {
            $warnings += "Diretório opcional não encontrado: $dir"
        }
    }
    
    # Verificar tamanho mínimo (servidor deve ter pelo menos alguns MB)
    $totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
    Write-Log "Tamanho total dos arquivos: $totalSizeMB MB" "INFO"
    
    if ($totalSizeMB -lt 10) {
        $warnings += "Tamanho total muito pequeno ($totalSizeMB MB). O servidor pode estar incompleto."
    }
    
    # Verificar se há executáveis ou scripts de inicialização
    $exeFiles = $allFiles | Where-Object { $_.Extension -eq ".exe" -or $_.Extension -eq ".bat" -or $_.Extension -eq ".sh" }
    if ($exeFiles.Count -gt 0) {
        Write-Log "Scripts/executáveis encontrados: $($exeFiles.Count)" "INFO"
        foreach ($exe in $exeFiles) {
            Write-Log "  - $($exe.Name)" "INFO"
        }
    }
    
    $isValid = $errors.Count -eq 0
    if ($isValid) {
        Write-Log "Validação concluída: Servidor parece estar completo!" "SUCCESS"
    } else {
        Write-Log "Validação concluída com erros!" "ERROR"
    }
    
    if ($warnings.Count -gt 0) {
        Write-Log "Avisos encontrados: $($warnings.Count)" "WARNING"
    }
    
    return @{
        Valid = $isValid
        Errors = $errors
        Warnings = $warnings
        FileCount = $allFiles.Count
        JarCount = $jarFiles.Count
        TotalSizeMB = $totalSizeMB
    }
}

# Função para remover pasta com retry e tratamento de erros
function Remove-PathSafely {
    param(
        [string]$Path,
        [int]$MaxRetries = 3,
        [int]$RetryDelay = 1000
    )
    
    if (-not (Test-Path $Path)) {
        return $true
    }
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            # Tentar encerrar processos que possam estar usando a pasta
            if ($i -gt 1) {
                Stop-ProcessesUsingPath -Path $Path
            }
            
            # Tentar remover arquivos individualmente primeiro
            Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    Remove-Item -Path $_.FullName -Force -ErrorAction Stop
                } catch {
                    # Se falhar, tentar desbloquear o arquivo
                    try {
                        $file = $_.FullName
                        if (Test-Path $file) {
                            $fileInfo = Get-Item $file -Force
                            $fileInfo.IsReadOnly = $false
                            Remove-Item -Path $file -Force -ErrorAction Stop
                        }
                    } catch {
                        # Ignorar erros individuais
                    }
                }
            }
            
            # Tentar remover a pasta
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            return $true
            
        } catch {
            if ($i -lt $MaxRetries) {
                Write-Log "Tentativa $i de $MaxRetries falhou ao remover $Path. Aguardando e tentando novamente..." "WARNING"
                Start-Sleep -Milliseconds $RetryDelay
            } else {
                Write-Log "ERRO: Não foi possível remover $Path após $MaxRetries tentativas: $_" "ERROR"
                return $false
            }
        }
    }
    
    return $false
}

Write-Log "=========================================" "INFO"
Write-Log "Iniciando instalação do Servidor Hytale" "INFO"
Write-Log "=========================================" "INFO"

# Verificação prévia: encerrar processos do downloader que possam estar rodando
Write-Log "Verificando processos em execução..." "INFO"
Stop-ProcessesUsingPath -Path $ExtractPath

# ETAPA 0: Verificar e baixar downloader.zip se necessário
Write-Log "ETAPA 0: Verificando downloader.zip..." "INFO"

if (-not (Test-Path $DownloaderZip)) {
    Write-Log "downloader.zip não encontrado. Baixando..." "INFO"
    Write-Log "URL: https://downloader.hytale.com/hytale-downloader.zip" "INFO"
    
    try {
        $downloaderUrl = "https://downloader.hytale.com/hytale-downloader.zip"
        
        # Normalizar caminho do downloader.zip
        $currentDir = (Get-Location).Path
        if (-not [System.IO.Path]::IsPathRooted($DownloaderZip)) {
            $cleanPath = $DownloaderZip -replace '^\.\\', '' -replace '^\./', ''
            $downloaderPath = Join-Path $currentDir $cleanPath
        } else {
            $downloaderPath = $DownloaderZip
        }
        $downloaderPath = [System.IO.Path]::GetFullPath($downloaderPath)
        
        Write-Log "Iniciando download de $downloaderUrl..." "INFO"
        Write-Log "Salvando em: $downloaderPath" "INFO"
        
        # Usar Invoke-WebRequest para baixar o arquivo
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloaderUrl -OutFile $downloaderPath -UseBasicParsing
        
        if (Test-Path $downloaderPath) {
            $fileSize = (Get-Item $downloaderPath).Length
            $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
            Write-Log "Download concluído! Tamanho: $fileSizeMB MB" "SUCCESS"
            
            # Atualizar a variável $DownloaderZip para usar o caminho completo
            $DownloaderZip = $downloaderPath
        } else {
            throw "Arquivo não foi baixado corretamente"
        }
    } catch {
        Write-Log "ERRO ao baixar downloader.zip: $_" "ERROR"
        Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
        Write-Log "Por favor, baixe manualmente o arquivo de:" "INFO"
        Write-Log "https://downloader.hytale.com/hytale-downloader.zip" "INFO"
        Write-Log "E coloque-o na pasta: $(Get-Location)" "INFO"
        exit 1
    }
} else {
    Write-Log "downloader.zip encontrado: $DownloaderZip" "SUCCESS"
    $fileSize = (Get-Item $DownloaderZip).Length
    $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
    Write-Log "Tamanho: $fileSizeMB MB" "INFO"
}

# ETAPA 1: Extração do Downloader
Write-Log "ETAPA 1: Extraindo downloader.zip..." "INFO"

try {
    # Limpar pasta de extração anterior se existir
    if (Test-Path $ExtractPath) {
        Write-Log "Removendo pasta de extração anterior..." "INFO"
        
        # Encerrar processos que possam estar usando arquivos na pasta
        Stop-ProcessesUsingPath -Path $ExtractPath
        
        # Tentar remover a pasta de forma segura
        if (-not (Remove-PathSafely -Path $ExtractPath)) {
            Write-Log "AVISO: Não foi possível remover completamente a pasta anterior. Tentando continuar..." "WARNING"
            # Tentar renomear a pasta antiga em vez de remover
            $oldPath = "$ExtractPath.old.$(Get-Date -Format 'yyyyMMddHHmmss')"
            try {
                Rename-Item -Path $ExtractPath -NewName (Split-Path -Leaf $oldPath) -Force -ErrorAction Stop
                Write-Log "Pasta antiga renomeada para: $oldPath" "INFO"
            } catch {
                Write-Log "AVISO: Não foi possível renomear pasta antiga. Continuando mesmo assim..." "WARNING"
            }
        }
    }
    
    # Criar pasta de extração
    if (-not (Test-Path $ExtractPath)) {
        New-Item -ItemType Directory -Path $ExtractPath -Force | Out-Null
    }
    
    # Extrair o arquivo ZIP
    Write-Log "Extraindo $DownloaderZip para $ExtractPath..." "INFO"
    Expand-Archive -Path $DownloaderZip -DestinationPath $ExtractPath -Force
    
    Write-Log "Extração concluída com sucesso!" "SUCCESS"
} catch {
    Write-Log "ERRO ao extrair downloader.zip: $_" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    
    # Tentar solução alternativa: extrair para pasta temporária
    Write-Log "Tentando solução alternativa: extrair para pasta temporária..." "INFO"
    try {
        $TempExtractPath = "$ExtractPath.temp.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Expand-Archive -Path $DownloaderZip -DestinationPath $TempExtractPath -Force
        Write-Log "Extração bem-sucedida em pasta temporária: $TempExtractPath" "SUCCESS"
        $ExtractPath = $TempExtractPath
    } catch {
        Write-Log "ERRO: Solução alternativa também falhou. Por favor, feche todos os processos que possam estar usando os arquivos e tente novamente." "ERROR"
        Write-Log "Você pode tentar:" "INFO"
        Write-Log "1. Fechar todas as janelas do PowerShell/CMD" "INFO"
        Write-Log "2. Verificar se o downloader está rodando e fechá-lo" "INFO"
        Write-Log "3. Reiniciar o computador se o problema persistir" "INFO"
        exit 1
    }
}

# ETAPA 2: Identificar e executar o downloader
Write-Log "ETAPA 2: Identificando downloader..." "INFO"

$DownloaderExe = $null
$PossibleNames = @("downloader.exe", "HytaleDownloader.exe", "downloader.bat", "download.bat", "run.bat", "install.bat")

foreach ($name in $PossibleNames) {
    $fullPath = Join-Path $ExtractPath $name
    if (Test-Path $fullPath) {
        $DownloaderExe = $fullPath
        Write-Log "Downloader encontrado: $name" "INFO"
        break
    }
}

# Se não encontrou, procurar qualquer .exe ou .bat na pasta
if (-not $DownloaderExe) {
    $exeFiles = Get-ChildItem -Path $ExtractPath -Filter "*.exe" -File
    $batFiles = Get-ChildItem -Path $ExtractPath -Filter "*.bat" -File
    
    if ($exeFiles.Count -gt 0) {
        $DownloaderExe = $exeFiles[0].FullName
        Write-Log "Downloader encontrado: $($exeFiles[0].Name)" "INFO"
    } elseif ($batFiles.Count -gt 0) {
        $DownloaderExe = $batFiles[0].FullName
        Write-Log "Downloader encontrado: $($batFiles[0].Name)" "INFO"
    }
}

if (-not $DownloaderExe) {
    Write-Log "ERRO: Não foi possível encontrar o executável do downloader" "ERROR"
    Write-Log "Conteúdo da pasta extraída:" "INFO"
    Get-ChildItem -Path $ExtractPath -Recurse | ForEach-Object { Write-Log "  $($_.FullName)" "INFO" }
    exit 1
}

# ETAPA 3: Verificar se o arquivo ZIP já existe antes de baixar
Write-Log "ETAPA 3: Verificando se o arquivo ZIP do servidor já existe..." "INFO"

# Calcular caminho completo de download
$currentDir = (Get-Location).Path
if (-not [System.IO.Path]::IsPathRooted($DownloadPath)) {
    $cleanPath = $DownloadPath -replace '^\.\\', '' -replace '^\./', ''
    $DownloadPathFull = Join-Path $currentDir $cleanPath
} else {
    $DownloadPathFull = $DownloadPath
}
$DownloadPathFull = [System.IO.Path]::GetFullPath($DownloadPathFull)

# Criar diretório de download se não existir
if (-not (Test-Path $DownloadPathFull)) {
    New-Item -ItemType Directory -Path $DownloadPathFull -Force | Out-Null
}

# Verificar se o arquivo ZIP já existe
# Procurar tanto na pasta de download quanto na pasta atual (onde o downloader pode salvar)
$existingZip = $null
$possibleZipNames = @(
    "game.zip",
    "hytale-server-download.zip",
    "hytale-server.zip",
    "server.zip"
)

# Lista de diretórios para procurar (pasta atual primeiro, depois pasta de download)
$searchPaths = @(
    $currentDir,      # Pasta atual (criar_server) - onde o downloader pode salvar
    $DownloadPathFull # Pasta de download configurada
)

foreach ($searchPath in $searchPaths) {
    foreach ($zipName in $possibleZipNames) {
        $zipPath = Join-Path $searchPath $zipName
        if (Test-Path $zipPath) {
            $existingZip = Get-Item $zipPath
            Write-Log "$zipName encontrado em $searchPath! Validando..." "INFO"
            
            # Validar o arquivo existente
            $isValid = $true
            $validationErrors = @()
            
            # Verificar tamanho
            if ($existingZip.Length -lt 1MB) {
                $isValid = $false
                $validationErrors += "Arquivo muito pequeno (possivelmente corrompido)"
            }
            
            # Verificar se é ZIP válido
            if ($isValid) {
                try {
                    $zip = [System.IO.Compression.ZipFile]::OpenRead($existingZip.FullName)
                    $entryCount = $zip.Entries.Count
                    $zip.Dispose()
                    
                    if ($entryCount -eq 0) {
                        $isValid = $false
                        $validationErrors += "ZIP vazio ou corrompido"
                    } else {
                        Write-Log "$zipName é válido! Tamanho: $([math]::Round($existingZip.Length / 1MB, 2)) MB, Entradas: $entryCount" "SUCCESS"
                    }
                } catch {
                    $isValid = $false
                    $validationErrors += "Não é um arquivo ZIP válido: $_"
                }
            }
            
            if ($isValid) {
                Write-Log "Arquivo ZIP válido encontrado. Pulando download." "SUCCESS"
                $SkipDownload = $true
                break
            } else {
                Write-Log "Arquivo ZIP existente é inválido:" "WARNING"
                foreach ($err in $validationErrors) {
                    Write-Log "  - $err" "WARNING"
                }
                Write-Log "Será necessário baixar novamente." "INFO"
                $existingZip = $null
            }
        }
    }
    if ($existingZip) { break }  # Se encontrou um arquivo válido, parar de procurar
}

# Se não encontrou arquivo válido, procurar por qualquer ZIP em ambos os diretórios
# EXCLUIR downloader.zip da busca (não é o arquivo do servidor)
if (-not $existingZip) {
    $allZips = @()
    
    # Procurar na pasta atual (excluindo downloader.zip)
    if (Test-Path $currentDir) {
        $currentZips = Get-ChildItem -Path $currentDir -Filter "*.zip" -File -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -ne "downloader.zip" }
        if ($currentZips) {
            $allZips += $currentZips
        }
    }
    
    # Procurar na pasta de download (excluindo downloader.zip)
    if (Test-Path $DownloadPathFull) {
        $downloadZips = Get-ChildItem -Path $DownloadPathFull -Filter "*.zip" -File -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -ne "downloader.zip" }
        if ($downloadZips) {
            $allZips += $downloadZips
        }
    }
    
    if ($allZips) {
        # Ordenar por data de modificação (mais recente primeiro) e pegar o primeiro
        $testZip = $allZips | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        Write-Log "Arquivo ZIP encontrado: $($testZip.Name) em $($testZip.DirectoryName). Validando..." "INFO"
        
        try {
            $zip = [System.IO.Compression.ZipFile]::OpenRead($testZip.FullName)
            $entryCount = $zip.Entries.Count
            $zip.Dispose()
            
            if ($testZip.Length -ge 1MB -and $entryCount -gt 0) {
                Write-Log "$($testZip.Name) é válido! Tamanho: $([math]::Round($testZip.Length / 1MB, 2)) MB, Entradas: $entryCount" "SUCCESS"
                Write-Log "Arquivo ZIP válido encontrado. Pulando download." "SUCCESS"
                $SkipDownload = $true
                $existingZip = $testZip
            }
        } catch {
            Write-Log "Arquivo ZIP encontrado é inválido. Será necessário baixar novamente." "WARNING"
        }
    }
}

# ETAPA 3.1: Executar o downloader (se necessário)
if (-not $SkipDownload) {
    Write-Log "ETAPA 3.1: Executando downloader para baixar arquivos do servidor..." "INFO"
    
    try {
        
        # Construir argumentos do downloader
        # O ProcessStartInfo.Arguments precisa de uma string com argumentos separados por espaço
        # Valores com espaços devem estar entre aspas
        $downloadPathQuoted = if ($DownloadPathFull -match '\s') {
            "`"$DownloadPathFull`""
        } else {
            $DownloadPathFull
        }
        
        # Executar o downloader de forma simples e direta
        Write-Log "Iniciando downloader..." "INFO"
        Write-Log "Comando: $DownloaderExe -download-path $downloadPathQuoted -patchline $Patchline -skip-update-check" "INFO"
        Write-Log "Caminho de download: $DownloadPathFull" "INFO"
        Write-Log "Aguarde, o download pode levar vários minutos..." "INFO"
        Write-Log ""
        
        try {
            # Executar usando Start-Process de forma síncrona mas sem redirecionamento que pode travar
            # O downloader provavelmente mostra progresso na janela ou precisa de interação
            $arguments = @(
                "-download-path",
                $DownloadPathFull,
                "-patchline",
                $Patchline,
                "-skip-update-check"
            )
            
            Write-Log "Executando downloader (isso pode levar vários minutos)..." "INFO"
            
            # Executar com janela visível para ver o progresso
            $proc = Start-Process -FilePath $DownloaderExe -ArgumentList $arguments -WorkingDirectory (Split-Path -Parent $DownloaderExe) -Wait -PassThru -WindowStyle Normal
            
            Write-Log "Processo do downloader finalizado." "INFO"
            
            if ($proc.ExitCode -eq 0) {
                Write-Log "Download concluído com sucesso!" "SUCCESS"
            } elseif ($null -eq $proc.ExitCode) {
                Write-Log "Download concluído (código de saída não disponível)" "INFO"
            } else {
                Write-Log "AVISO: Downloader retornou código de saída $($proc.ExitCode)" "WARNING"
                Write-Log "Verifique se o download foi concluído corretamente verificando o diretório: $DownloadPathFull" "INFO"
            }
            
        } catch {
            Write-Log "ERRO ao executar downloader: $_" "ERROR"
            Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
            throw
        }
    } catch {
        Write-Log "ERRO ao executar downloader: $_" "ERROR"
        exit 1
    }
} else {
    if ($existingZip) {
        Write-Log "ETAPA 3.1: Pulando download (arquivo ZIP válido já existe)" "INFO"
    } else {
        Write-Log "ETAPA 3.1: Pulando download (SkipDownload ativado manualmente)" "INFO"
    }
}

# ETAPA 4: Extrair arquivos baixados e localizar servidor
Write-Log "ETAPA 4: Processando arquivos baixados..." "INFO"

# Usar o arquivo existente se foi encontrado, senão procurar novamente
$GameZip = $null
$DownloadedZip = $null

if ($existingZip) {
    # Usar o arquivo que já foi validado
    $GameZip = $existingZip
    Write-Log "Usando arquivo ZIP existente: $($GameZip.Name)" "INFO"
} else {
    # Procurar pelo arquivo baixado (tanto na pasta atual quanto na pasta de download)
    Write-Log "Verificando se o arquivo ZIP do servidor foi baixado..." "INFO"
    
    # Lista de diretórios para procurar
    $searchPaths = @(
        $currentDir,      # Pasta atual (criar_server)
        $DownloadPathFull # Pasta de download configurada
    )
    
    # Lista de nomes possíveis para o arquivo ZIP do servidor
    $possibleZipNames = @(
        "game.zip",
        "hytale-server-download.zip",
        "hytale-server.zip",
        "server.zip"
    )
    
    # Procurar pelos nomes específicos primeiro em ambos os diretórios
    foreach ($searchPath in $searchPaths) {
        if (Test-Path $searchPath) {
            foreach ($zipName in $possibleZipNames) {
                $zipPath = Join-Path $searchPath $zipName
                if (Test-Path $zipPath) {
                    $GameZip = Get-Item $zipPath
                    Write-Log "$zipName encontrado em $searchPath!" "SUCCESS"
                    break
                }
            }
            if ($GameZip) { break }
        }
    }
    
    # Se não encontrou nenhum dos nomes específicos, procurar por qualquer ZIP em ambos os diretórios
    # EXCLUIR downloader.zip da busca (não é o arquivo do servidor)
    if (-not $GameZip) {
        Write-Log "Nenhum arquivo ZIP conhecido encontrado. Procurando por outros arquivos ZIP..." "WARNING"
        $allZips = @()
        
        foreach ($searchPath in $searchPaths) {
            if (Test-Path $searchPath) {
                $foundZips = Get-ChildItem -Path $searchPath -Filter "*.zip" -File -ErrorAction SilentlyContinue | 
                    Where-Object { $_.Name -ne "downloader.zip" }
                if ($foundZips) {
                    $allZips += $foundZips
                }
            }
        }
        
        if ($allZips) {
            $DownloadedZip = $allZips | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            Write-Log "Arquivo ZIP encontrado: $($DownloadedZip.Name) em $($DownloadedZip.DirectoryName)" "INFO"
        }
    }
}

# Validar arquivo ZIP se encontrado
if ($GameZip) {
    Write-Log "Validando $($GameZip.Name)..." "INFO"
    Write-Log "Nome: $($GameZip.Name)" "INFO"
    Write-Log "Tamanho: $([math]::Round($GameZip.Length / 1MB, 2)) MB" "INFO"
    Write-Log "Data de modificação: $($GameZip.LastWriteTime)" "INFO"
    
    # Verificar se o arquivo tem tamanho válido (pelo menos 1 MB)
    if ($GameZip.Length -lt 1MB) {
        Write-Log "ERRO: $($GameZip.Name) parece estar corrompido ou incompleto (tamanho muito pequeno)" "ERROR"
        exit 1
    }
    
    # Verificar se é um arquivo ZIP válido tentando abrir
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($GameZip.FullName)
        $entryCount = $zip.Entries.Count
        $zip.Dispose()
        Write-Log "$($GameZip.Name) é válido! Contém $entryCount arquivos/entradas" "SUCCESS"
    } catch {
        Write-Log "ERRO: $($GameZip.Name) não é um arquivo ZIP válido: $_" "ERROR"
        exit 1
    }
    
    # Extrair o arquivo ZIP para o diretório do servidor
    if (-not (Test-Path $ServerPath)) {
        Write-Log "Criando diretório do servidor: $ServerPath" "INFO"
        New-Item -ItemType Directory -Path $ServerPath -Force | Out-Null
    }
    
    Write-Log "Extraindo $($GameZip.Name) para: $ServerPath" "INFO"
    try {
        Expand-Archive -Path $GameZip.FullName -DestinationPath $ServerPath -Force
        Write-Log "Extração concluída com sucesso!" "SUCCESS"
    } catch {
        Write-Log "ERRO ao extrair $($GameZip.Name): $_" "ERROR"
        exit 1
    }
    
    # Validar arquivos extraídos
    Write-Log "Validando arquivos extraídos..." "INFO"
    $validation = Test-ServerFiles -ServerPath $ServerPath
    
    if (-not $validation.Valid) {
        Write-Log "ERRO: Validação dos arquivos do servidor falhou!" "ERROR"
        foreach ($err in $validation.Errors) {
            Write-Log "  - $err" "ERROR"
        }
        exit 1
    }
    
    if ($validation.Warnings.Count -gt 0) {
        Write-Log "AVISOS durante validação:" "WARNING"
        foreach ($warning in $validation.Warnings) {
            Write-Log "  - $warning" "WARNING"
        }
    }
    
    Write-Log "Validação completa: Todos os arquivos estão nos lugares corretos!" "SUCCESS"
    Write-Log ""
    
} elseif ($DownloadedZip) {
    # Fallback: usar outro ZIP se game.zip não foi encontrado
    Write-Log "AVISO: game.zip não encontrado, mas arquivo ZIP encontrado: $($DownloadedZip.Name)" "WARNING"
    Write-Log "Tamanho do arquivo: $([math]::Round($DownloadedZip.Length / 1MB, 2)) MB" "INFO"
    
    # Extrair o ZIP baixado para o diretório do servidor
    if (-not (Test-Path $ServerPath)) {
        Write-Log "Criando diretório do servidor: $ServerPath" "INFO"
        New-Item -ItemType Directory -Path $ServerPath -Force | Out-Null
    }
    
    Write-Log "Extraindo arquivos do servidor para: $ServerPath" "INFO"
    try {
        Expand-Archive -Path $DownloadedZip.FullName -DestinationPath $ServerPath -Force
        Write-Log "Extração concluída com sucesso!" "SUCCESS"
        
        # Validar arquivos extraídos
        Write-Log "Validando arquivos extraídos..." "INFO"
        $validation = Test-ServerFiles -ServerPath $ServerPath
        
        if (-not $validation.Valid) {
            Write-Log "ERRO: Validação dos arquivos do servidor falhou!" "ERROR"
            foreach ($err in $validation.Errors) {
                Write-Log "  - $err" "ERROR"
            }
            exit 1
        }
        
        if ($validation.Warnings.Count -gt 0) {
            Write-Log "AVISOS durante validação:" "WARNING"
            foreach ($warning in $validation.Warnings) {
                Write-Log "  - $warning" "WARNING"
            }
        }
        
        Write-Log "Validação completa: Todos os arquivos estão nos lugares corretos!" "SUCCESS"
        Write-Log ""
        
    } catch {
        Write-Log "ERRO ao extrair arquivo baixado: $_" "ERROR"
        exit 1
    }
} else {
    Write-Log "ERRO: Nenhum arquivo ZIP do servidor foi encontrado em $DownloadPathFull" "ERROR"
    Write-Log "Arquivos procurados: game.zip, hytale-server-download.zip, hytale-server.zip, server.zip" "INFO"
    Write-Log "Verificando conteúdo do diretório de download..." "INFO"
    if (Test-Path $DownloadPathFull) {
        $downloadContents = Get-ChildItem -Path $DownloadPathFull -ErrorAction SilentlyContinue
        if ($downloadContents) {
            Write-Log "Conteúdo do diretório de download:" "INFO"
            foreach ($item in $downloadContents) {
                Write-Log "  - $($item.Name) ($($item.GetType().Name))" "INFO"
            }
        } else {
            Write-Log "Diretório de download está vazio" "ERROR"
        }
    } else {
        Write-Log "Diretório de download não existe: $DownloadPathFull" "ERROR"
    }
    Write-Log ""
    Write-Log "Por favor, execute o downloader novamente para baixar o arquivo ZIP do servidor" "ERROR"
    exit 1
}

# Localizar HytaleServer.jar e Assets.zip
Write-Log "Localizando arquivos do servidor..." "INFO"

$HytaleServerJar = $null
$AssetsZipPath = $null

# Procurar HytaleServer.jar na pasta Server
$serverDir = Join-Path $ServerPath "Server"
if (Test-Path $serverDir) {
    $jarPath = Join-Path $serverDir "HytaleServer.jar"
    if (Test-Path $jarPath) {
        $HytaleServerJar = Get-Item $jarPath
        Write-Log "HytaleServer.jar encontrado: $($HytaleServerJar.FullName)" "SUCCESS"
    } else {
        Write-Log "AVISO: HytaleServer.jar não encontrado em $serverDir" "WARNING"
        # Procurar qualquer arquivo .jar na pasta Server
        $jars = Get-ChildItem -Path $serverDir -Filter "*.jar" -File -ErrorAction SilentlyContinue
        if ($jars) {
            $HytaleServerJar = $jars | Select-Object -First 1
            Write-Log "Arquivo JAR encontrado: $($HytaleServerJar.Name)" "INFO"
        }
    }
} else {
    Write-Log "AVISO: Pasta Server não encontrada em $ServerPath" "WARNING"
    # Procurar em toda a estrutura
    $allJars = Get-ChildItem -Path $ServerPath -Filter "HytaleServer.jar" -Recurse -File -ErrorAction SilentlyContinue
    if ($allJars) {
        $HytaleServerJar = $allJars | Select-Object -First 1
        Write-Log "HytaleServer.jar encontrado: $($HytaleServerJar.FullName)" "SUCCESS"
    }
}

# Procurar Assets.zip
$assetsZipPath = Join-Path $ServerPath "Assets.zip"
if (Test-Path $assetsZipPath) {
    $AssetsZipPath = (Get-Item $assetsZipPath).FullName
    Write-Log "Assets.zip encontrado: $AssetsZipPath" "SUCCESS"
} else {
    Write-Log "AVISO: Assets.zip não encontrado em $ServerPath" "WARNING"
    # Procurar em toda a estrutura
    $allAssetsZips = Get-ChildItem -Path $ServerPath -Filter "Assets.zip" -Recurse -File -ErrorAction SilentlyContinue
    if ($allAssetsZips) {
        $AssetsZipPath = ($allAssetsZips | Select-Object -First 1).FullName
        Write-Log "Assets.zip encontrado: $AssetsZipPath" "SUCCESS"
    }
}

if (-not $HytaleServerJar) {
    Write-Log "ERRO: HytaleServer.jar não foi encontrado" "ERROR"
    Write-Log "Por favor, verifique se o download foi concluído corretamente" "INFO"
    exit 1
}

if (-not $AssetsZipPath) {
    Write-Log "AVISO: Assets.zip não foi encontrado" "WARNING"
    Write-Log "O servidor será iniciado sem o parâmetro --assets" "WARNING"
}

# ETAPA 5: Verificar e instalar dependências (se necessário)
Write-Log "ETAPA 5: Verificando dependências..." "INFO"

# Verificar .NET Framework
$dotNetVersion = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" -Name Release -ErrorAction SilentlyContinue
if ($dotNetVersion) {
    Write-Log ".NET Framework instalado (Release: $($dotNetVersion.Release))" "INFO"
} else {
    Write-Log "AVISO: .NET Framework pode não estar instalado" "WARNING"
}

# Verificar Java (se necessário para o servidor)
if (Test-Command "java") {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    Write-Log "Java encontrado: $javaVersion" "INFO"
} else {
    Write-Log "AVISO: Java não encontrado (pode ser necessário para o servidor)" "WARNING"
}

# ETAPA 6: Configurar servidor (criar arquivos de configuração se necessário)
Write-Log "ETAPA 6: Verificando configurações do servidor..." "INFO"

$ConfigFile = Join-Path $ServerPath "serverconfig.json"
if (-not (Test-Path $ConfigFile)) {
    Write-Log "Arquivo de configuração não encontrado. Criando configuração padrão..." "INFO"
    
    $defaultConfig = @{
        serverName = "Hytale Server"
        serverDescription = "Servidor Hytale"
        maxPlayers = 50
        port = 25565
    } | ConvertTo-Json -Depth 10
    
    try {
        Set-Content -Path $ConfigFile -Value $defaultConfig -Encoding UTF8
        Write-Log "Configuração padrão criada em $ConfigFile" "INFO"
    } catch {
        Write-Log "AVISO: Não foi possível criar arquivo de configuração: $_" "WARNING"
    }
}

# ETAPA 7: Inicializar o servidor
Write-Log "ETAPA 7: Inicializando servidor..." "INFO"

# Verificar se Java está disponível
if (-not (Test-Command "java")) {
    Write-Log "ERRO: Java não está instalado ou não está no PATH" "ERROR"
    Write-Log "Por favor, instale o Java e adicione-o ao PATH do sistema" "ERROR"
    exit 1
}

try {
    $jarPath = $HytaleServerJar.FullName
    $jarDir = Split-Path -Parent $jarPath
    
    Write-Log "Iniciando servidor Hytale..." "INFO"
    Write-Log "JAR: $jarPath" "INFO"
    Write-Log "Diretório de trabalho: $jarDir" "INFO"
    Write-Log ""
    
    # Construir comando Java
    $javaArgs = @(
        "-jar",
        $jarPath
    )
    
    # Adicionar parâmetro --assets se Assets.zip foi encontrado
    if ($AssetsZipPath) {
        $javaArgs += "--assets"
        $javaArgs += $AssetsZipPath
        Write-Log "Assets: $AssetsZipPath" "INFO"
    } else {
        Write-Log "AVISO: Iniciando sem Assets.zip" "WARNING"
    }
    
    $javaCommand = "java " + ($javaArgs -join " ")
    Write-Log "Comando: $javaCommand" "INFO"
    Write-Log ""
    
    # Iniciar servidor com janela visível
    Write-Log "=========================================" "SUCCESS"
    Write-Log "Servidor Hytale iniciando..." "SUCCESS"
    Write-Log "=========================================" "SUCCESS"
    Write-Log ""
    Write-Log "O servidor será iniciado em uma janela separada." "INFO"
    Write-Log "Você pode acompanhar o progresso na janela do servidor." "INFO"
    Write-Log ""
    Write-Log "Para parar o servidor, feche a janela do servidor ou pressione Ctrl+C nesta janela." "INFO"
    Write-Log ""
    
    # Iniciar o processo do servidor usando Java
    $serverProcess = Start-Process -FilePath "java" -ArgumentList $javaArgs -WorkingDirectory $jarDir -PassThru -WindowStyle Normal
    
    if ($serverProcess) {
        Write-Log "Servidor iniciado com sucesso!" "SUCCESS"
        Write-Log "PID do processo: $($serverProcess.Id)" "SUCCESS"
        Write-Log ""
        Write-Log "Aguardando servidor iniciar..." "INFO"
        
        # Aguardar um pouco para verificar se o processo ainda está rodando
        Start-Sleep -Seconds 3
        
        if (-not $serverProcess.HasExited) {
            Write-Log "Servidor está rodando!" "SUCCESS"
            Write-Log ""
            Write-Log "O servidor continuará rodando em segundo plano." "INFO"
            Write-Log "Para encerrar o servidor, feche a janela do servidor ou use o Gerenciador de Tarefas." "INFO"
            Write-Log ""
            Write-Log "Pressione qualquer tecla para encerrar este script (o servidor continuará rodando)..." "INFO"
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        } else {
            Write-Log "AVISO: O servidor encerrou imediatamente. Verifique os logs para mais detalhes." "WARNING"
            if ($serverProcess.ExitCode) {
                Write-Log "Código de saída: $($serverProcess.ExitCode)" "WARNING"
            }
        }
    } else {
        throw "Falha ao iniciar o processo do servidor"
    }
    
} catch {
    Write-Log "ERRO ao inicializar servidor: $_" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    Write-Log ""
    Write-Log "Tentando método alternativo..." "INFO"
    
    # Método alternativo: executar diretamente
    try {
        if ($ServerExecutable -like "*.bat") {
            & cmd.exe /c "`"$ServerExecutable`""
        } else {
            & $ServerExecutable
        }
    } catch {
        Write-Log "ERRO: Método alternativo também falhou: $_" "ERROR"
        exit 1
    }
}

Write-Log "Instalação e inicialização concluídas!" "SUCCESS"

# Script de Inicialização Rápida do Servidor Hytale
# Use este script após a instalação para iniciar o servidor novamente

param(
    [string]$ServerPath = ".\hytale-server"
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Iniciando Servidor Hytale" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se Java está disponível
function Test-Command {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

if (-not (Test-Command "java")) {
    Write-Host "ERRO: Java não está instalado ou não está no PATH" -ForegroundColor Red
    Write-Host "Por favor, instale o Java e adicione-o ao PATH do sistema" -ForegroundColor Yellow
    exit 1
}

# Normalizar caminho do servidor
$currentDir = (Get-Location).Path
if (-not [System.IO.Path]::IsPathRooted($ServerPath)) {
    $cleanPath = $ServerPath -replace '^\.\\', '' -replace '^\./', ''
    $ServerPath = Join-Path $currentDir $cleanPath
} else {
    $ServerPath = $ServerPath
}
$ServerPath = [System.IO.Path]::GetFullPath($ServerPath)

# Procurar HytaleServer.jar
$HytaleServerJar = $null
$ServerDir = Join-Path $ServerPath "Server"

if (Test-Path $ServerDir) {
    $jarPath = Join-Path $ServerDir "HytaleServer.jar"
    if (Test-Path $jarPath) {
        $HytaleServerJar = Get-Item $jarPath
        Write-Host "HytaleServer.jar encontrado: $($HytaleServerJar.FullName)" -ForegroundColor Green
    } else {
        # Procurar qualquer arquivo .jar na pasta Server
        $jars = Get-ChildItem -Path $ServerDir -Filter "*.jar" -File -ErrorAction SilentlyContinue
        if ($jars) {
            $HytaleServerJar = $jars | Select-Object -First 1
            Write-Host "Arquivo JAR encontrado: $($HytaleServerJar.Name)" -ForegroundColor Green
        }
    }
} else {
    Write-Host "AVISO: Pasta Server não encontrada em $ServerPath" -ForegroundColor Yellow
    # Procurar em toda a estrutura
    $allJars = Get-ChildItem -Path $ServerPath -Filter "HytaleServer.jar" -Recurse -File -ErrorAction SilentlyContinue
    if ($allJars) {
        $HytaleServerJar = $allJars | Select-Object -First 1
        Write-Host "HytaleServer.jar encontrado: $($HytaleServerJar.FullName)" -ForegroundColor Green
    }
}

if (-not $HytaleServerJar) {
    Write-Host "ERRO: HytaleServer.jar não encontrado!" -ForegroundColor Red
    Write-Host "Execute primeiro o script de instalação: .\instalar-hytale-server.ps1" -ForegroundColor Yellow
    exit 1
}

# Procurar Assets.zip
$AssetsZipPath = $null
$assetsZip = Join-Path $ServerPath "Assets.zip"
if (Test-Path $assetsZip) {
    $AssetsZipPath = (Get-Item $assetsZip).FullName
    Write-Host "Assets.zip encontrado: $AssetsZipPath" -ForegroundColor Green
} else {
    Write-Host "AVISO: Assets.zip não encontrado em $ServerPath" -ForegroundColor Yellow
    # Procurar em toda a estrutura
    $allAssetsZips = Get-ChildItem -Path $ServerPath -Filter "Assets.zip" -Recurse -File -ErrorAction SilentlyContinue
    if ($allAssetsZips) {
        $AssetsZipPath = ($allAssetsZips | Select-Object -First 1).FullName
        Write-Host "Assets.zip encontrado: $AssetsZipPath" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Iniciando servidor..." -ForegroundColor Cyan
Write-Host "Diretório de trabalho: $ServerPath" -ForegroundColor Gray
Write-Host ""

# Construir comando Java
$jarPath = $HytaleServerJar.FullName
$jarDir = Split-Path -Parent $jarPath

$javaArgs = @(
    "-jar",
    $jarPath
)

# Adicionar parâmetro --assets se Assets.zip foi encontrado
if ($AssetsZipPath) {
    $javaArgs += "--assets"
    $javaArgs += $AssetsZipPath
    Write-Host "Comando: java -jar `"$jarPath`" --assets `"$AssetsZipPath`"" -ForegroundColor Gray
} else {
    Write-Host "AVISO: Iniciando sem Assets.zip" -ForegroundColor Yellow
    Write-Host "Comando: java -jar `"$jarPath`"" -ForegroundColor Gray
}
Write-Host ""

try {
    # Iniciar o processo do servidor usando Java
    $process = Start-Process -FilePath "java" -ArgumentList $javaArgs -WorkingDirectory $jarDir -PassThru -WindowStyle Normal -NoNewWindow:$false
    
    if ($process) {
        Write-Host "Servidor iniciado! PID: $($process.Id)" -ForegroundColor Green
        Write-Host "O servidor está rodando em uma janela separada." -ForegroundColor Cyan
        Write-Host "Para parar o servidor, feche a janela do servidor ou use o Gerenciador de Tarefas." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Pressione qualquer tecla para encerrar este script (o servidor continuará rodando)..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        throw "Falha ao iniciar o processo do servidor"
    }
    
} catch {
    Write-Host "ERRO ao iniciar servidor: $_" -ForegroundColor Red
    exit 1
}

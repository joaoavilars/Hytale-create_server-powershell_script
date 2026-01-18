# Script para limpar processos do downloader que possam estar bloqueando arquivos
# Execute este script se tiver problemas de acesso negado

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Limpando processos do Hytale Downloader" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$processNames = @("hytale-downloader", "downloader", "hytale")
$found = $false

foreach ($procName in $processNames) {
    $procs = Get-Process -Name "*$procName*" -ErrorAction SilentlyContinue
    foreach ($proc in $procs) {
        $found = $true
        Write-Host "Processo encontrado: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Yellow
        Write-Host "  Caminho: $($proc.Path)" -ForegroundColor Gray
        
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction Stop
            Write-Host "  ✓ Processo encerrado com sucesso" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Erro ao encerrar processo: $_" -ForegroundColor Red
        }
    }
}

# Procurar processos na pasta de extração
$extractPath = ".\downloader-extracted"
if (Test-Path $extractPath) {
    Write-Host ""
    Write-Host "Verificando processos usando arquivos em: $extractPath" -ForegroundColor Cyan
    
    try {
        $allProcs = Get-Process -ErrorAction SilentlyContinue
        foreach ($proc in $allProcs) {
            try {
                if ($proc.Path -and $proc.Path -like "*$extractPath*") {
                    $found = $true
                    Write-Host "Processo encontrado: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Yellow
                    Write-Host "  Caminho: $($proc.Path)" -ForegroundColor Gray
                    
                    try {
                        Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                        Write-Host "  ✓ Processo encerrado com sucesso" -ForegroundColor Green
                    } catch {
                        Write-Host "  ✗ Erro ao encerrar processo: $_" -ForegroundColor Red
                    }
                }
            } catch {
                # Ignorar processos que não podem ser acessados
            }
        }
    } catch {
        Write-Host "AVISO: Erro ao verificar processos: $_" -ForegroundColor Yellow
    }
}

if (-not $found) {
    Write-Host ""
    Write-Host "Nenhum processo relacionado encontrado." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Aguardando 2 segundos para processos encerrarem..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    Write-Host "Limpeza concluída!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Agora você pode tentar executar o script de instalação novamente." -ForegroundColor Cyan
Write-Host "Pressione qualquer tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

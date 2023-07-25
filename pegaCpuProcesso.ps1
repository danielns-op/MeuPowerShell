# ---- VARIAVEIS ---- #
$diretorioLog = ""
$arquivoLog = "cpu.txt"
[int]$cpuCores = $env:NUMBER_OF_PROCESSORS
$maioresProcesso = @()
# ------------------- #

# ---- FUNCOES ------ #
function verificaArquivosDeLog {
  if ( -not ( Test-Path $diretorioLog) ) {
    New-Item -Path $diretorioLog -ItemType Directory
    "Diretório '$diretorioLog' criado com sucesso."
  }

  if ( -not (Test-Path "$diretorioLog\$arquivoLog")) {
    New-Item -Path "$diretorioLog\$arquivoLog" -ItemType File
    "Arquivo de log '$diretorioLog\$arquivoLog' criado com sucesso."
  }
}


function gravaLog($mensagem) {
  $time = (Get-Date -UFormat "%d/%m/%Y %H:%M:%S")

  Out-File -Filepath $caminhoLog -Append -InputObject "$time - $mensagem"
}


function listaProcessoComMaisUsoCPU {
    # zerando a lista dos processos
    $maioresProcesso = @()

    foreach ($processo in ((Get-Counter "\Processo(*)\% tempo de processador" -ErrorAction SilentlyContinue | Select-Object -ExcludeProperty CounterSamples).CounterSamples | Sort-Object -Property CookedValue | select -Last 5)[0..2] )  {
    
        $novoObjeto = [PSCustomObject]@{
            Nome = $processo.InstanceName
            Caminho = ($processo.Path).Replace("\% tempo de processador", "\processo de identificação")
            CPU = [math]::Round([double]$processo.CookedValue / $cpuCores, 2)
        }

        $mensagem = "Processo: $($novoObjeto.Nome) CPU: $($novoObjeto.CPU)"
        gravaLog($mensagem)
        write-host($mensagem) -ForegroundColor Red
        Write-Host("|----Gravado no Log...----|") -ForegroundColor Green

        $maioresProcesso += $novoObjeto
    }
}


function main {
    verificaArquivosDeLog

    while ($true) {
        $percentualUsoCpu = (Get-WmiObject Win32_Processor).LoadPercentage

        if ($percentualUsoCpu -gt 20) {
            gravaLog("CPU TOTAL: $percentualUsoCpu")
            Write-Host("Consumo de CPU atual: $percentualUsoCpu") -ForegroundColor Red
            listaProcessoComMaisUsoCPU
        } else {
            Write-Host("Consumo de CPU atual: $percentualUsoCpu") -ForegroundColor Yellow
        }

        write-Host("-" * 40) -ForegroundColor Cyan
   }
}
# ------------------- #

# ---- EXECUCAO ----- #
main
# ------------------- #

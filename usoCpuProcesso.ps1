$caminhoLog = ""

function gravaLog($mensagem) {
  $time = (Get-Date -UFormat "%d/%m/%Y %H:%M:%S")

  Out-File -Filepath $caminhoLog -Append -InputObject "$time - $mensagem"
}

while ($true) {

    $percentualUsoCpu = (Get-WmiObject Win32_Processor).LoadPercentage
    if ($percentualUsoCpu -gt 20) {
        Write-Host("Consumo de CPU atual: $percentualUsoCpu") -ForegroundColor Red
        Write-Host("|----Gerando Log...----|") -ForegroundColor Green
        $listaProcesso = @()

        $grupoProcesso = (Get-WmiObject -Class Win32_Process -Filter "name='svchost.exe'" |
        Select-Object @{N="Processo"; E={($_.CommandLine -Split ' ')[2]}}, ProcessId)

        foreach ($processo in $grupoProcesso) {
            $idProcesso = $processo.ProcessId

            try {
    
                if ($idProcesso) {
                    $pathProcesso = ((Get-Counter "\Processo(svchost*)\processo de identificação" -ErrorAction SilentlyContinue |
                    Select-Object -ExpandProperty CounterSamples |
                    Where-Object {$_.RawValue -eq $idProcesso}).Path).Replace("\processo de identificação", "\% tempo de processador")
                    $cpuCores = $env:NUMBER_OF_PROCESSORS
                    $cpu = ([Math]::Round(((Get-Counter $pathProcesso -ErrorAction SilentlyContinue | Select-Object -ExpandProperty CounterSamples).CookedValue / $cpuCores)))
    
                    $processoObj = [PSCustomObject]@{
                        nomeProcesso = $processo.Processo
                        PID = $idProcesso
                        CPU = $cpu
                    }

                    #$processoObj
                    $listaProcesso += $processoObj
                }
            } catch {
                Write-Host("Processo ($idProcesso) não existe mais!")
            }
        }
        foreach ($item in ($listaProcesso | Sort-Object CPU -Descending | Select-Object -First 3)) {
            gravaLog($item)
        }
        Write-Host("|----Log gerado----|") -ForegroundColor Green
    } else {
        Write-Host("Consumo de CPU atual: $percentualUsoCpu") -ForegroundColor Yellow
    }
    write-Host("-" * 40) -ForegroundColor Cyan
}

# rebootPendent.ps1                                              #
# -------------------------------------------------------------- #
# Autor: Daniel Noronha da Silva                                 #
#  Data: 21/09/2022                                              #
# -------------------------------------------------------------- #
# Script para pegar o statua do servidor, o mesmo retorna se o   #
# servidor está 'OK', 'Indiponível" ou se está precisando ser    #
# reiniciado.                                                    #
# -------------------------------------------------------------- #
# Modo de uso:                                                   #
#    - Execução no computador local:                             #
#        ./rebootPendent.ps1 hostname                            #
#                                                                #
#    - Para executar em vários servidores:                       #
#        ./rebootPendent.ps1 server1 server2 server3 server4     #
#                                                                #
#    - Para execução de forma remota:                            #
#        Invoke-Command -ComputerName SERVIDOR                   #
#                       -FilePath ./rebootPendent.ps1            #
#                       -ArgumentList "SERVIDOR"                 #
#                       -Credential "usuario"                    #
#                                                                #
#    - Para executar de forma remota em vários servidores:       #
#        Invoke-Command -ComputerName SERVIDOR                   #
#                       -FilePath ./rebootPendent.ps1            #
#        -ArgumentList "SERVER1", "SERVER2", "SERVER3", "SERVER4"#
#                       -Credential "usuario"                    #
#      Onde: O SERVER vai ser o servidor onde você vai executar  #
#            o script para os demais servidores, esse server ele #
#            tem que ter permissão de acessar o demais servidores#
#            da rede, eu aconselho a fazer no servidor do AD.    #
#            O parametro -ArgumentList é onde você vai adicionar #
#            a lista de servidores.                              #
#                                                                #
#    - Execução em uma quantidade muito grande de servidores:    #
#        -> Você pode criar um LOOP onde o mesmo cria uma lista  #
#           de servidores e pode adicionar essa lista na várivel #
#           '$serverList', Exemplo:                              #
#                            $serverList = LISTA_SERVER          #
#        -> Ou você pode utilizar um arquivo contendo a lista    #
#           dos servidores e adiciona o caminho do arquivo na    #
#           variável '$serverList', Exemplo:                     #
#                                     $serverList = gc Arquivo   #
#    - Caso você adicione os servidores como uma lista ou como   #
#      um arquivo direto na variável '$serverList' a forma de    #
#      execução do script é essa:                                #
#        --> Execução local: ./rebootPendent.ps1                 #
#        --> Execução remota: Invoke-Command                     #
#                               -ComputerName SERVIDOR           #
#                               -FilePath ./rebootPendent.ps1    #
#                               -Credential "usuario"            #
# -------------------------------------------------------------- #

# para execução adicionando os servidores vinha linha de comando.
$serverList = $args

# caso queira passar um arquivo com o nome de vários servidores é
# só descomentar a linha abaixo e passar o path.
# o gc é um alias para Get-Content, onde o mesmo vai pegar as
# informações contidas no arquivo.
#$serverList = gc caminho_do_arquivo

Write-Host "STATUS                SERVIDOR" -backgroundcolor White -ForegroundColor Blue
foreach ($server in $serverList) {
    try {
        $basekey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $server)
        $key = $basekey.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\")
        $subkeys = $key.GetSubKeyNames()
        $key.Close()
        $basekey.Close()

        if ($subkeys | where {$_ -eq "RebootPending"}) {
            Write-Host "Pendente;            " $server -ForegroundColor Yellow

            # descomente a linha abaixo para realizar o restart do servidor
            #Restart-Computer -ComputerName $server -Confirm
        } else {
            Write-Host "OK                   " $server -ForegroundColor Green
        }
    } catch {
        Write-Host "Indisponível         " $server -ForegroundColor Red
    }
}

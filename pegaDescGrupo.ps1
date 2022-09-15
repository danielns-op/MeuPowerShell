# ------------------------------------------------------ #
# pegaDescGrupo.ps1                                      #
# ------------------------------------------------------ #
# Autor: Daniel Noronha da Silva                         #
#  Data: 13/09/2022                                      #
# ------------------------------------------------------ #
# O script lista os grupos do Active Directory de um     #
# usuário e coleta as descrições desse grupo e salva     #
# tudo em um arquivo .csv.                               #
# Modo de usar:                                          #
#  ./pegaDescGrupo.ps1 USER HOSTNAME ADMIN               #
#   - USER - Usuário no qual será realizado a listagem   #
#            dos grupos no AD.                           #
#   - HOSTNAME - Micro para qual o arquivo CSV será      #
#                cópiado.                                #
#   - ADMIN - Usuário com acessar ao Active Directory.   #
#                                                        #
# Para que o mesmo seja executado de forma remota, será  #
# necessário executar conforme abaixo:                   #
#   Invoke-Command                                       #
#       -ComputerName servidor_remoto                    #
#       -FilePath path_onde_encontra-se_o_script         #
#       -ArgumentList "USUARIO", "hostname", "user"      #
#       -Credential "Domain\User"                        #
#                                                        #
# Explicando:                                            #
# -ComputerName - Nome do servidor que será executado o  #
#                 programa.                              #
# -FilePath - Caminho onde encontra-se o script.         #
# -ArgumentList - Lista de 3 elementos contendo o Usuario#
#                 que será realizado a pesquisa no AD,   #
#                 hostname para onde será cópiado o CSV  #
#                 que foi gerado e o usuario para acessar#
#                 a máquina de destino onde será cópiado #
#                 o CSV.                                 #
# -Credential - Usuário para se conecetar no AD.         #
#                                                        #
# ------------------------------------------------------ #

# Variaveis -------------------------------------------- # 
$usuario = $args[0]
$micro = $args[1]
$credencial = $args[2]
$destino = "c$"
$nome_arquivo = "./infoGrupos_${usuario}.csv"
# ------------------------------------------------------ #

# Execucao --------------------------------------------- #
if ( -not $usuario ) {
    Write-Output("`n`nÉ necessário adicionar: `n -Um usuário para pesquisa. `n -Um hostname para onde o arquivo será copiado `n -Um usuário para se conectar na máquina onde o arquivo será cópiado. `n  Exemplo: `n ./pegaDescGrupo.ps1 user hostname credenciais`n`n")
} else {
    foreach ($grupo in $(Get-ADPrincipalGroupMembership -Identity $usuario -Server capgv.intra.bnb)) {
        $dados = (Get-ADGroup -Identity $grupo -Server capgv.intra.bnb -Properties description | select Name, SamAccountName, Description)
        
        # criando o objeto que será usado para gravar os dados no arquivo CSV.
        $csvObjeto = [PSCustomObject]@{
            Nome = $dados.Name
            NomeGrupo = $dados.SamAccountName
            Descricao = $dados.Description
        }
        Export-Csv -InputObject $csvObjeto -NoTypeInformation -Encoding UTF8 -Path $nome_arquivo -Append
    }
    # Criando um drive temporário para copiar o arquivo.
    New-PSDrive -Name Y -PSProvider FileSystem -Root "\\$micro\$destino" -Credential $credencial
    Copy-Item -Path $nome_arquivo -Destination Y:\ -Recurse -ErrorAction SilentlyContinue
}
# ------------------------------------------------------ #

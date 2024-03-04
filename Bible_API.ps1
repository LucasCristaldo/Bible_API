# ======= Functions =======

function get_credentials{
    param($credentials_path, $log_path)

    # Tentando pegar a key para ter acesso a API
    try {

    $key = $(Get-Content $credentials_path ).Split("=")
    # A key se encontra em ".\config.env"
    # Dei 'split' para dividir em 2 e poder usar o comando abaixo

    $hi = @{[string]$key[0]=[string]$key[-1]} 
    # O " [-1] " pega o último valor de um array/lista

    return $hi
    }
    catch
    {
        # Não achou a key de acesso
        Add-Content -Path $log_path -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | [CRITICAL] | INVALID CREDENTIALS PATH" 
        Add-Content -Path $log_path -Value " "  
        Add-Content -Path $log_path -Value $Error[0..1]
        Add-Content -Path $log_path -Value " "

        exit
    }


}

function get_books_chapters{
    param($log_path, $biblia_url, $hi, $path1, $base_url, $r_biblia_id)

    Add-Content -Path $log_path -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | [INFO] | START ALL BOOKS REQUEST" 
    $livro_url = $biblia_url + "/books"

    $r_livro = Invoke-WebRequest -uri $livro_url -Headers $hi -UseBasicParsing

    $r_livro = $($r_livro.Content | Out-String | ConvertFrom-Json).data

    foreach ($r_livros in $r_livro)
    {
        # Nome do livro
        $livro_name = $r_livros.name


        # Criando a pasta de acordo com o nome do livro
        $path2 = $path1 + "/" + $livro_name

        if (-not (test-path $path2))
        {
            mkdir $path2
        }

        # ID do livro
        $livro_id = $r_livros.id

        # Url dos capítulos
        $capitulos_url = $base_url + "/bibles/" + $r_biblia_id + "/books/" + $livro_id + "/chapters"
    
        $r_capitulos = Invoke-WebRequest -Uri $capitulos_url -Headers $hi -UseBasicParsing

        $r_capitulos = $($r_capitulos.Content | Out-String | ConvertFrom-Json).data

        Add-Content -Path $log_path -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | [INFO] | START COLLECT FOR BOOK: $livro_name"


        foreach ($capitulos in $r_capitulos)
        {
            $capitulos_id = $capitulos.id
            $capitulos_name = $capitulos.reference
    
            # Criando o arquivo txt
            $path3 = $path2 + "/" + $capitulos_name + ".txt"
        
            # Url dos versículos
            $conteudo_url = $base_url + "/bibles/" + $r_biblia_id + "/chapters/" + $capitulos_id
    
            $conteudo = Invoke-WebRequest -Uri $conteudo_url -Headers $hi -UseBasicParsing
    
            $conteudo = $($conteudo.Content | Out-String | ConvertFrom-Json).data
        

            $conteudo = $conteudo.Content

            # Adicionando o conteúdo no arquivo txt
            Add-Content -Path $path3 -Value $conteudo
    
        }

    }





}



# ============== Constantes ============== #

$log_path = "C:\Users\lucas\OneDrive\Área de Trabalho\Powershell - Udemy\Powershell\APIs\Bible_API\logs.txt"


# Base url da API
$base_url = "https://api.scripture.api.bible/v1"

$pt_bible_id = "d63894c8d9a7a503-01"

# ========== MAIN ========== #

Add-Content -Path $log_path -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | [INFO] | API REQUEST STARTED" 

$hi = get_credentials -credentials_path ".\config.env" -log_path $log_path
    
# Pegando o nome da Bíblia para colocar no nome da pasta
$biblia_url = $base_url + "/bibles/" + $pt_bible_id 
try {
    $r_biblia_nome_e_id = Invoke-WebRequest -Uri $biblia_url -Headers $hi -UseBasicParsing
}
catch 
{
    $r_biblia_nome_e_id_url = $base_url + "/bibles"

    $r = Invoke-WebRequest -uri $r_biblia_nome_e_id_url -Headers $hi -UseBasicParsing

    $r = $($r.Content | Out-String | ConvertFrom-Json).data 

    foreach ($bibles in $r)
    {
        if ($bibles.language.id.tolower().trim() -eq "por")
        {
            if ($bibles.name.tolower().trim().replace(" ", "_") -eq "biblia_livre_para_todos")
            {
                $pt_bible_id = $bibles.id
                
            }      
        }
    
    }
}

try {

$r_biblia_nome_e_id = Invoke-WebRequest -Uri $biblia_url -Headers $hi -UseBasicParsing

$r_biblia_nome_e_id = $($r_biblia_nome_e_id.Content | Out-String | ConvertFrom-Json).data

# Nome da bíblia BR
$r_biblia_nome = $($r_biblia_nome_e_id.name).ToLower().Trim().Replace(" ", "_")

# Código/ID da bíblia BR
$r_biblia_id = $r_biblia_nome_e_id.id

} 
catch 
{
    Add-Content -Path $log_path -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | [ERROR] | INVALID BOOK NAME/ID REQUEST PATH" 
    Add-Content -Path $log_path -Value " "
    # Se houver algum erro, esse comando abaixo irá me mostrar qual foi o problema
    Add-Content -Path $log_path -Value $Error[0..1]
    Add-Content -Path $log_path -Value " "
    exit
}

$path1 = [string]$(pwd) + "/" + $r_biblia_nome

if (-not (test-path $path1))
{
    mkdir $path1
}



# Pegando os livros/books
get_books_chapters -log_path $log_path -biblia_url $biblia_url -hi $hi -path1 $path1 -base_url $base_url -r_biblia_id $r_biblia_id
    

Add-Content -Path $log_path -Value "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | [INFO] | API REQUEST SUCESSFUL" 
Add-Content -Path $log_path -Value " "
Add-Content -Path $log_path -Value " "




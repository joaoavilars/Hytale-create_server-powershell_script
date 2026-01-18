# Scripts de Instalação e Gerenciamento do Servidor Hytale

Este conjunto de scripts PowerShell automatiza a instalação, configuração e inicialização do servidor Hytale.

## 📋 Arquivos Principais

O projeto contém 3 scripts principais:

1. **`instalar-hytale-server.ps1`** - Script principal de instalação
2. **`iniciar-servidor.ps1`** - Script para iniciar o servidor após a instalação
3. **`limpar-processos.ps1`** - Script auxiliar para limpar processos bloqueadores

## ⚠️ Requisitos

- **Windows 10/11**
- **PowerShell** (já incluído no Windows)
- **Java 25** instalado e configurado no PATH do sistema (obrigatório)
- **Conta Hytale** criada no site oficial do Hytale
- **Execução como Administrador** (obrigatório)

### ⚡ Java 25 - Requisito Obrigatório

O servidor Hytale **exige especificamente o Java 25** para executar. É **essencial** que:

1. ✅ O **Java 25** esteja instalado no Windows
2. ✅ O Java esteja configurado no **PATH do sistema**
3. ✅ O Java esteja acessível via linha de comando

**Verificar instalação do Java:**

Abra o PowerShell e execute:
```powershell
java -version
```

Você deve ver algo como:
```
openjdk version "25.0.1" 2025-10-21 LTS
```

Se o comando não funcionar ou mostrar uma versão diferente, você precisa:

1. Baixar e instalar o **Java 25** (JDK)
2. Adicionar o Java ao PATH do sistema Windows
3. Reiniciar o PowerShell/Terminal
4. Verificar novamente com `java -version`

> ⚠️ **IMPORTANTE:** O servidor Hytale não funcionará com versões anteriores do Java. É obrigatório ter o Java 25 instalado e configurado.

## 🚀 Como Usar

### Passo 1: Preparação

1. **Instale o Java 25** (se ainda não tiver):
   - Baixe o Java 25 JDK do site oficial
   - Instale seguindo as instruções
   - Configure no PATH do sistema Windows
   - Verifique com: `java -version`

2. Abra o **PowerShell como Administrador**:
   - Clique com o botão direito no menu Iniciar
   - Selecione "Windows PowerShell (Admin)" ou "Terminal (Admin)"

3. Navegue até a pasta dos scripts:
   ```powershell
   cd D:\Projetos\Hytale-server\criar_server
   ```

4. Se necessário, permita a execução de scripts:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### Passo 2: Instalação

Execute o script de instalação:

```powershell
.\instalar-hytale-server.ps1
```

#### O que o script faz:

1. **Baixa automaticamente** o `downloader.zip` se não existir
2. **Extrai** o downloader
3. **Executa** o downloader para baixar os arquivos do servidor
4. **Valida** os arquivos baixados
5. **Configura** o servidor
6. **Inicia** o servidor automaticamente

### Passo 3: Autenticação do Downloader

Quando o downloader for executado, **uma segunda janela será aberta** mostrando:

```
Acesse o seguinte link no seu navegador para autenticar:
https://...
```

1. **Copie o link** mostrado na janela
2. **Cole no navegador** e acesse
3. **Faça login** com sua conta Hytale (criada no site oficial)
4. **Aprove a autenticação** do downloader
5. Aguarde o download dos arquivos do servidor ser concluído

> ⏱️ O download pode levar vários minutos dependendo da sua conexão.

### Passo 4: Autenticação do Servidor

Após o servidor iniciar, você verá o console do servidor. Será necessário autenticar o servidor do jogo:

1. No console do servidor, digite:
   ```
   /auth login device
   ```

2. Será exibido um **novo link de autenticação**

3. **Copie o link** e cole no navegador

4. **Aprove a autenticação** do servidor

5. Para salvar a autenticação e não precisar autenticar novamente ao reiniciar, digite:
   ```
   /auth persistence Encrypted
   ```

> ✅ Após configurar a persistência, você poderá parar e iniciar o servidor sem precisar autenticar novamente.

## 📝 Scripts Disponíveis

### `instalar-hytale-server.ps1`

Script principal que realiza toda a instalação e configuração do servidor.

**Parâmetros opcionais:**

```powershell
# Instalação padrão
.\instalar-hytale-server.ps1

# Especificar caminho do servidor
.\instalar-hytale-server.ps1 -ServerPath "C:\MeuServidorHytale"

# Especificar caminho de download
.\instalar-hytale-server.ps1 -DownloadPath "C:\Downloads\Hytale"

# Usar patchline beta
.\instalar-hytale-server.ps1 -Patchline "beta"

# Pular download (se já baixou)
.\instalar-hytale-server.ps1 -SkipDownload
```

**O que faz:**
- ✅ Baixa o `downloader.zip` automaticamente se não existir
- ✅ Extrai e executa o downloader
- ✅ Baixa os arquivos do servidor
- ✅ Valida e extrai os arquivos
- ✅ Configura o servidor
- ✅ Inicia o servidor automaticamente

### `iniciar-servidor.ps1`

Script para iniciar o servidor após a instalação (sem repetir todo o processo).

```powershell
# Iniciar servidor (caminho padrão)
.\iniciar-servidor.ps1

# Iniciar servidor (caminho personalizado)
.\iniciar-servidor.ps1 -ServerPath "C:\MeuServidorHytale"
```

**O que faz:**
- ✅ Localiza o `HytaleServer.jar`
- ✅ Localiza o `Assets.zip`
- ✅ Executa: `java -jar Server\HytaleServer.jar --assets Assets.zip`
- ✅ Inicia o servidor em uma janela separada

### `limpar-processos.ps1`

Script auxiliar para limpar processos que possam estar bloqueando arquivos.

```powershell
.\limpar-processos.ps1
```

**Quando usar:**
- Se encontrar erros de "acesso negado" ao executar os scripts
- Se processos do downloader estiverem travados
- Antes de executar novamente o script de instalação após um erro

## 🔧 Estrutura de Arquivos

Após a instalação, a estrutura será:

```
criar_server/
├── downloader.zip                    # Downloader baixado automaticamente
├── downloader-extracted/             # Downloader extraído
│   └── hytale-downloader-windows-amd64.exe
├── hytale-server-download/          # Pasta de download (opcional)
├── hytale-server/                     # Servidor instalado
│   ├── Assets.zip                    # Assets do jogo
│   ├── Server/
│   │   ├── HytaleServer.jar          # Executável do servidor
│   │   └── Licenses/
│   └── serverconfig.json             # Configuração do servidor
├── instalar-hytale-server.ps1       # Script de instalação
├── iniciar-servidor.ps1              # Script de inicialização
├── limpar-processos.ps1              # Script de limpeza
└── install-log.txt                   # Log da instalação
```

## 🔐 Autenticação em Duas Etapas

O processo de autenticação acontece em **duas etapas distintas**:

### Etapa 1: Autenticação do Downloader

- Ocorre durante a instalação
- Necessária para baixar os arquivos do servidor
- Janela separada mostra o link de autenticação
- Aprove no navegador com sua conta Hytale

### Etapa 2: Autenticação do Servidor

- Ocorre após o servidor iniciar
- Necessária para o servidor funcionar
- Execute no console: `/auth login device`
- Aprove o link no navegador
- Configure persistência: `/auth persistence Encrypted`

## 📊 Logs e Arquivos Gerados

- **`install-log.txt`** - Log completo da instalação
- **`server-output.log`** - Log de saída do servidor (na pasta do servidor)

## ⚠️ Solução de Problemas

### Erro: "Java não encontrado" ou "Java não está instalado"

**Solução:**
1. Instale o **Java 25 JDK** (obrigatório - versões anteriores não funcionam)
2. Adicione o Java ao PATH do sistema Windows:
   - Abra "Variáveis de Ambiente" no Windows
   - Adicione o caminho do Java (ex: `C:\Program Files\Java\jdk-25\bin`)
   - Reinicie o PowerShell/Terminal
3. Verifique com: `java -version`
4. Deve mostrar: `openjdk version "25.x.x"` ou similar

### Erro: "Access to the path ... is denied"

Execute o script de limpeza:
```powershell
.\limpar-processos.ps1
```

Depois tente novamente.

### Erro: "downloader.zip não encontrado"

O script baixa automaticamente. Se falhar:
1. Verifique sua conexão com a internet
2. Baixe manualmente de: https://downloader.hytale.com/hytale-downloader.zip
3. Coloque na pasta `criar_server`

### Servidor não inicia

1. **Verifique se o Java 25 está instalado**: `java -version`
2. Verifique os logs em `install-log.txt`
3. Verifique se `HytaleServer.jar` existe em `hytale-server\Server\`
4. Verifique se `Assets.zip` existe em `hytale-server\`
5. Tente executar manualmente:
   ```powershell
   cd hytale-server
   java -jar Server\HytaleServer.jar --assets Assets.zip
   ```

### Autenticação não funciona

1. Certifique-se de usar uma conta Hytale válida
2. Verifique se o link de autenticação não expirou (geralmente válido por alguns minutos)
3. Tente novamente com `/auth login device`

## 📚 Comandos Úteis do Servidor

Após o servidor iniciar, você pode usar os seguintes comandos no console:

- `/auth login device` - Autenticar o servidor
- `/auth persistence Encrypted` - Salvar autenticação permanentemente
- `/stop` - Parar o servidor graciosamente
- `/help` - Ver lista de comandos disponíveis

## 🔄 Reiniciar o Servidor

Para reiniciar o servidor após pará-lo:

```powershell
.\iniciar-servidor.ps1
```

Se você configurou a persistência da autenticação (`/auth persistence Encrypted`), não precisará autenticar novamente.

## 📞 Suporte

Em caso de problemas:

1. Verifique o arquivo `install-log.txt` para detalhes
2. Verifique os logs do servidor em `hytale-server\server-output.log`
3. Execute `.\limpar-processos.ps1` se houver problemas de acesso a arquivos
4. **Certifique-se de que o Java 25 está instalado e configurado corretamente**

## 📄 Licença

Este script é fornecido "como está" para facilitar a instalação do servidor Hytale. O servidor Hytale e seus componentes são propriedade da Hypixel Studios.

---

**Desenvolvido para facilitar a instalação e gerenciamento do servidor Hytale**

**Requisito obrigatório: Java 25 instalado e configurado no Windows**

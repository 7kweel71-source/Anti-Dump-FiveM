# CRÉDITOS TOTALMENTE PARA O 77ryoiki


# ANT-DUMPER Multi-Framework

Recurso sem dependências obrigatórias, compatível com:

- Standalone
- QBCore
- QBox (`qbx_core`)
- Creative
- vRP

## Instalação

1. Coloque a pasta dentro de `resources`.
2. Renomeie a pasta, caso queira; o NUI detecta o nome automaticamente.
3. Configure `config.lua`.
4. Adicione no `server.cfg`:

```cfg
ensure ANT-DUMPER-FXAP-COMMUNITY
```

O nome usado no `ensure` deve ser exatamente o nome da pasta.

## Framework

Use no `config.lua`:

```lua
Config.Framework = "auto"
```

Valores aceitos: `auto`, `standalone`, `qbcore`, `qbox`, `creative` e `vrp`.

Em modo automático, Creative e vRP podem ser identificados como `vrp`, pois normalmente usam o mesmo resource. Isso não impede o funcionamento. Para exibir `creative` nos logs, selecione-o manualmente.

## Banimento

O recurso possui banimento próprio em `bans.json`, baseado prioritariamente na license do jogador. Assim, ele não depende da tabela de bans de nenhum framework.

Também são fornecidos os exports de servidor:

```lua
exports["NOME_DO_RECURSO"]:IsIdentifierBanned(identifier)
exports["NOME_DO_RECURSO"]:UnbanIdentifier(identifier)
exports["NOME_DO_RECURSO"]:GetBans()
```

## Bypass administrativo

Por padrão, a ACE é `antidumper.bypass`.

Exemplo por license:

```cfg
add_ace identifier.license:COLOQUE_A_LICENSE_AQUI antidumper.bypass allow
```

Exemplo por grupo:

```cfg
add_ace group.admin antidumper.bypass allow
```

## Webhook

Defina em `config.lua`:

```lua
Config.Webhook.Url = "SEU_WEBHOOK"
```

Deixe vazio para não enviar logs ao Discord.

## Comando de desbanimento

Pelo console do servidor:

```cfg
antidumper_unban license:IDENTIFICADOR
```

Para permitir o comando dentro do jogo:

```cfg
add_ace group.admin antidumper.admin allow
```

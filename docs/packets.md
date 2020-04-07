# Packets and storage data structures

## Packets

### RPC

#### name

Receive: string

Send: string

#### world id

Receive: nil

Send: string

### Module

#### update position

Receive:

```lua
{
    id: string,
    pos: {x: number, y: number}
}
```

Send: nil

#### update input

Receive:

```lua
{
    id: string,
    inp: number
}
```

Send: nil

#### update state

Receive: nil

Send:

```lua
{
    pos: [id: {x: number, y: number}],
    inp: [id: number],
}
```

#### update jump

Receive:

```lua
{
    id: string,
    jmp: number
}
```

Send: nil

#### do spawn

Receive:

```lua
{
    id: string,
    col: string
}
```

Send:

```lua
{
    id: string,
    col: string
}
```

#### update color

Receive:

```lua
{
    id: string,
    col: string
}
```

Send:

```lua
{
    id: string,
    col: string
}
```

#### initial state

Receive: nil

Send:

```lua
{
    pos: {id: {x: number, y: number }}[],
    inp: {id: number}[],
    col: {id: string}[],
    nms: {id: string}[]
}
```

## Storage

### global_data

Fetched and stored by the server when the user requests a new name. Owned by no one, but reading is publicly available.

#### names

```lua
{
    names: string[]
}
```

### player_data

#### position_CharacterName

Fetched and used by the server when the character spawns or leaves. Owned by the player, readable solely by the player.

```lua
{
    x: number,
    y: number
}
```

#### last_character

Fetched and used by the client when preparing the character listing. Owned by the player, readable solely by the player.

```lua
{
    name: String,
    color: String
}
```

#### characters

Fetched and used by the client when preparing the character listing. Owned by the player, readable solely by the player.

```lua
{
    characters: {name: string, color: string}[]
}
```

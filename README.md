# AsGangBuilder

Ressource FiveM (ESX avec job secondaire `job2`) pour créer et gérer des gangs en jeu : builder admin, coffre ox_inventory, menu boss (membres + fonds) et menu d'interaction F7.

## Dépendances

- `es_extended` (fork avec `job2` / `setJob2`)
- `oxmysql`
- `ox_inventory`

## Installation

1. Importer `install.sql` (table `gangs`).
2. Placer la ressource dans `resources/` et ajouter `ensure AsGangBuilder` dans `server.cfg`.
3. Donner l'accès au builder :

```
add_ace group.admin gangbuilder.admin allow
```

## Utilisation

- `/gangbuilder` — builder, réservé à l'ace `gangbuilder.admin`.
- Point boss — gestion des membres et des fonds du gang, réservé au grade `boss`.
- Coffre — accessible aux membres du gang, sur place.
- `F7` — menu d'interaction pour les membres d'un gang.

## Configuration

Distances, capacité du coffre, plafond de transaction et nom du grade boss dans `config.lua`.

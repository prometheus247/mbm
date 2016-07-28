# mbm
MBM - Multi Bot Maintainer

The MBM is a script to maintain order with several bots running https://github.com/prometheus247/PokemonGo-Bot at a time.
Its designed to run as "brainless" as possible, doing the thinking while you can concentrate on other things.

Assumptions the script has:

- The PoGo Usernames ending with @gmail.com
- The mbm.sh will be executed as root manually or automatically as cron
- Your config are looking like this (1 config per bot):
-   PokemonGo-Bot/configs/config_01
-   PokemonGo-Bot/configs/config_02
-   [...]
-   PokemonGo-Bot/configs/config_99

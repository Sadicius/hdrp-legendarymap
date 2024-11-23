# HDRP Legendary map
This use Legendary Map

Once you use the map it will show you information about where the wild animal could be, you must go to the area and try to find it, you will see some clues when you are close..
- The map self-destructs after use
- The animals are selected randomly
- The areas are selected randomly

Therefore, multiple possibilities are generated when searching for the legendary animal throughout the territory
![image](https://github.com/user-attachments/assets/5025adfe-ac6a-4492-baed-9451fcacf166)

# Install
- Add folder in your resources
- Add item in your shared/items.lua
```lua
legendarymap     = {name = 'legendarymap',  label = 'Map animal leyendary', weight = 125, type = 'item', image = 'treasuremap.png', unique = false, useable = true,  shouldClose = true, description = 'A map with shared location details'},
```

REQUIRES RSG FRAMEWORK
REQUIRES ox_lib

# Credits
- Reference: rsg-legendary
- Discord CFX
- It has been reworked from scratch by #sadicius

If you want me to keep sharing stuff, don't change the name.

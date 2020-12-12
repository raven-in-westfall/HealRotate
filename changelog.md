## HealRotate Changelog

#### v1.3.0

- HealRotate now play a sound when you need to heal (You can disable it in the options)
- Added an option to not show up the window each time you join a raid
- Added an option to have the window show up when you target a heal-able boss
- Rotation will now reset when you kill the boss
- Adds an option to report the main rotation on multiple lines
- Adds a `report` slash command to print the rotation to the configured channel

#### v1.3.0

- Adds arcane shot test mode
- Adds sound when user is the next to heal (Added setting toggle to switch if off)
- Adds some logic to rotation, HealRotate will skip a healer if it's heal ability isn't ready
- Update zhCN & zhTW locales, thanks to LeePich
- Adds raid check and update display when player leave combat
- Fix rotation logic with dead or offline players
- Adds healers heal cooldown display
- Use a font that support unicode character for asian player names

#### v1.2.0

- Main window don't show up in battleground anymore
- Fix potential bug in rotation when backup healer use heal
- Adds `/heal backup` command to manually alert backup if required (use that with a macro)
- Remove turn to heal from a healer that dies and set it to the following in rotation
- Adds healer list and heal synchronization
- Adds resync and raid refresh feature to the reset button

#### v1.1.0

- Adds HealRotate window
- Adds raid healers detection
- Adds rotation handling
- Adds main window position change using drag & drop
- Adds main window position lock setting
- Adds healer death and disconnection display on healer frames
- Adds healer group and order change using drag & drop
- Adds lock/unlock slash command option
- Adds toggle slash command option
- Adds "broadcast rotation setup to raid chat"
- Adds rotation reset button to re-initialize betweeen/after pulls
- Adds whisper message to next healer and all backup healers when you miss
- Adds close button to top bar
- Adds option to hide main window when not in a raid

- Change base slash command to display available options
- Change slash command settings to `/heal settings`

- Splits code in multiple files
- Moves all lua files to src/
- Use first target change event to update raid status if player login while already in raid
- Updates game interface version to 11303

#### v1.0.1

- Fix missing libs in toc file

#### v1.0.0

- Adds slash command
- Adds settings
- Adds base combat log handling
- Adds automatic success and fail heal messages
- Adds frFR locale
- Adds znTW locale
- Adds zhCN locale

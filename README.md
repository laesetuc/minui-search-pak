# minui-search-pak
A MinUI app that allows searching of ROM collections.

## Requirements

This pak is designed for and tested with the following MinUI Platforms and devices:

- `tg5040`: Trimui Brick (formerly `tg3040`)

## Installation

1. Mount your MinUI SD card.
2. Download the latest [release](https://github.com/laesetuc/minui-search-pak/releases) from GitHub.
3. Copy the zip file to the correct platform folder in the "/Tools" directory on the SD card.
4. Extract the zip in place, then delete the zip file.
5. Confirm that there is a `/Tools/$PLATFORM/Favorites.pak/launch.sh` file on your SD card.
6. Unmount your SD Card and insert it into your MinUI device.

Note: The platform folder name is based on the name of your device. For example, if you are using a TrimUI Brick, the folder is "tg5040". Alternatively, if you're not sure which folder to use, you can copy the .pak folders to all the platform folders.

## Usage

### Search

Use the keyboard to enter a search term.  
Press A to select a character, or B to erase a character.
Press X to search, or Y to exit

### Search Results

Matching search results will be displayed in a list.
Select a game and press A to launch the game, or B to return to the Search screen.

### Previous Search

When launching search again, the Previous search results will be displayed.

## Acknowledgements

- [MinUI](https://github.com/shauninman/MinUI) by Shaun Inman
- [minui-keyboard](https://github.com/josegonzalez/minui-keyboard), [minui-list](https://github.com/josegonzalez/minui-list) and [minui-presenter](https://github.com/josegonzalez/minui-presenter) by Jose Diaz-Gonzalez
- Also, thank you, Jose Diaz-Gonzalez, for your pak repositories, which this project is based on.

## License

This project is released under the MIT License. For more information, see the [LICENSE](LICENSE) file.

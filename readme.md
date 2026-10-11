__[Main Page](https://github.com/rossoliny/bvo-another)__
###### Language
| _[Russian](https://github.com/rossoliny/bvo-another/blob/master/readme.RU.md)_ | _[English](https://github.com/rossoliny/bvo-another/blob/master/readme.md)_|
|-|-|
----

# Welcome 
  
  Hello, my name is *[Rossoliny](https://github.com/rossoliny)* and this is a *__NEW__* dev page of ***__Bleach vs One Piece Another__*** map.
  
  Many years ago Kuragane created the original BvO map, but then he abandoned it and Unryze continued development and we got BvO Another 1.1a that is considered to be the most balanced and bugfree version of all.  
  Unfortunately version 1.1b is probably lost and Unryze seems to lose interest to this map and is not likely to finish 1.1c so I decided to continue development.

# Building the map

The complete editable map contents live in `w3x-content/`, using the map's internal paths and filenames. The main script is `w3x-content/scripts/war3map.j`.

From the repository root, run `bash build-w3x.sh` for a development build with cheats, or `bash build-w3x.sh --release` for a release with all cheat code removed. Add `--lang en`, `--lang ru`, or `--lang en,ru` to choose languages; the default is EN. Outputs include the language suffix, for example `build/BvO_Another_release_en.w3x` and `build/BvO_Another_release_ru.w3x`.

RU builds merge ready text fields from `w3x-content-ru/` into the base profiles in memory, retaining the original filenames inside the map. Missing translations use the base text. See [the translation format](w3x-content-ru/README.md); gameplay fields, scripts and binary objects cannot be supplied as translations.

Builds use Bash and the bundled tools in `toolkit/`; no base map or Ladik is required. Source files stay unchanged, messages go to the console, and temporary files and the packer's report are cleaned up after each run.

The selected JASS is prepared once in a temporary file inside `build/` for checking and shared use across languages, then removed. `toolkit/pack-map.lua` runs W3x2Lni's `pack` command in the console and checks the archive's files against their sources and expected text substitutions.

# Contribution

Rossoliny's BvO is open source.  

The original BvO from Kurogane was protected in many ways so it is not possible for this map to be completely open source. However, I myself will not try to add any kinds of protection to this map and all changes that *__I make__* will be open source. So, you can freely download this repository and explore the sources.  

Or you can contribute to this project to help me with development.

# Bugs and Features

If you want to report some bugs, glitches, abuses or share some ideas about new features and enhancements please create new issue __*[here](https://github.com/rossoliny/bvo-another/issues)*__.  
Please don't forget to add an appropriate tag if you create a new issue.

# Contacts
You can directly contact me in Discord if you want:
* *[Rossoliny#0686](https://discord.com/users/0686)*

# Releases
#### *[Latest release](https://github.com/rossoliny/bvo-another/releases/tag/%231.4)*
#### *[All releases](https://github.com/rossoliny/bvo-another/releases)*

#### Game does not see the map?
* *It is recommended to put map file into "Map/Download".*
* *If game does not see the map it means that the name of the file is too long and you need to rename it to something shorter.*

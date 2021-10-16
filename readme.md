# Just intonation trainer

## Dependencies

- My `Ratio` class, found [here](https://github.com/mattiashallsten/mh-extensions).

## Usage

To run the page, open <parent.scd> in SuperCollider and place the
cursor right under where it says s.waitForBoot. Hit Cmd+Enter on Mac,
Ctrl+Enter on PC.

## Add ratios

To add ratios, open the file `ratios.json` and start writing below where it says
"Add new ratio here:".

The new ratio must follow the same scheme as the other ones, namely:

```json
{
	"ratio": <ratio>,
	"description": "<description>",
	"limit": <the limit as a whole-number,
	"fav": <1 if it is a favourite, 0 if not"
},
```

Make sure to add the comma at the end, and to have quotation marks around the
description.

## TODO

- [x] Instead of loading an external file for the ratios (`ratios.scd`), write
      the ratios in a `.json` file and parse them in SuperCollider using:
	  
``` supercollider
var file = File.read("ratios.json", "r");
var string = file.readAllString;
 
var ratios = string.parseJSON;
```
 
- [x] Make use of my `Ratio` SuperCollider class to calculate the limit, not
      having the user manually input the limit themselves.
	  

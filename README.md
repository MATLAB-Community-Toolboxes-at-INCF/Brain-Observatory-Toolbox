# Brain-Observatory-Toolbox
A MATLAB toolbox for accessing and working with the neural recording public dataset releases from the Allen Brain Observatory resource \[1\]. 

**NOTE**: Releases for the current version (0.9) represent a *working prototype* intended for evaluation. Feedback is encouraged and welcomed (one or more channels to be established soon). 

## About the Allen Brain Observatory datasets
[Data releases](https://portal.brain-map.org/latest-data-release) from the Allen Brain Observatory include two datasets of neural activity recorded from the mouse visual cortex during visual stimulus presentation:  

| Dataset | Recording Type | Nickname | Details |
| --- | --- | --- | --- |
| Visual Coding 2P \[2\] | Two-photon calcium imaging | "ophys" (optical physiology) | [details](http://portal.brain-map.org/explore/circuits/visual-coding-2p) |
| Visual Coding Neuropixels \[3\] | Large-scale neural probe recordings | "ephys" (electrophysiology) | [details](https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels) |

Technical white papers available for each dataset (see Details) provide detailed information describing the experiments, recordings, and computational pipelines. 

## About the Brain Observatory Toolbox (BOT) 
 
The Brain Observatory Toolbox (BOT) provides a uniform interface for users to conveniently access and work with these Visual Coding neural datasets. 

The BOT interface provides a tabular representation of available dataset items and an object representation of specific dataset items: 
![alt text](https://github.com/emeyers/Brain-Observatory-Toolbox/blob/backend/BOTDataSchematic.png?raw=true)

**Key Points:**
* Supported dataset items include experimental sessions (both 2P and Neuroxels datasets) as well as probes, channels, and units (for the Neuropixels dataset). 
* Tabular indexing or unique item identifiers can be used to select specific item(s) of interest from available items tables for item object creation. 
* Item object properties allow inspection and computation of direct, derived, and file-linked values associated to an item. 
* Item object methods allow computations of values determined with additional user-specified arguments. 
* The BOT provides local caching of retrieved item information, object representations, and file contents, to provide the fastest possible initial and repeat performance.

To preview the BOT in action: view the [Ephys Demo](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F6aee4c33-d05e-4715-82ab-748f121adcad%2Fd61de411-5e28-4eba-8c36-c8b1df0435fc%2Ffiles%2FEphysDemo.mlx&embed=web) and/or the [Ophys Demo](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F6aee4c33-d05e-4715-82ab-748f121adcad%2Fd61de411-5e28-4eba-8c36-c8b1df0435fc%2Ffiles%2FOphysDemo.mlx&embed=web).

## Installation Instructions

1. Download the latest release, either by
   1. Downloading the `.zip` file from GitHub and unzipping via preferred system tool
   1. Cloning the GitHub `master` branch<sup>1</sup>
1. Add the root directory of the unzipped contents to the MATLAB path, either by:
   1. Navigating to root directory in the _Current Folder_ browser and selecting _Add to Path_<sup>2</sup> in the right-click context menu
   1. Selecting root directory in the Set Path dialog from the _Environment_ section of the _Home_ tab
   1. Calling `addpath(<root directory>)` in the _Command Window_
<sup>1. This branch will be renamed soon to remove abhorrent associations 
<sup>2. Note it is unnecessary to add subdirectories to the MATLAB path; all contents of the `+bot` package are made available by adding the base directory</sup>

#### Required products
* MATLAB (R2021a)
* Image Processing Toolbox (if running the Visual Coding 2P demonstration `OphysDemo.mlx`)

## Getting started
Four MATLAB live scripts are provided to help get started: 

* `EphysDemo.mlx` and `OphysDemo.mlx` demonstrate simple representative neuroscientific analysis using the BOT with the Visual Coding Neuropixels and Visual Coding 2P datasets, respectively
* `EphysTutorial.mlx` and `OphysTutorial.mlx` provide more step-by-step instruction and "under the hood" technical detail about using the BOT and the datasets 

Or to get a fast first look yourself, enter the following commands in MATLAB: 
```
sessions = bot.fetchSessions('ephys'); 
head(sessions)
```
----
#### References

[1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: [portal.brain-map.org/explore/circuits](http://portal.brain-map.org/explore/circuits).

[2] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P Dataset. Available from: [portal.brain-map.org/explore/circuits/visual-coding-2p](http://portal.brain-map.org/explore/circuits/visual-coding-2p).

[3] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels Dataset. Available from: [portal.brain-map.org/explore/circuits/visual-coding-neuropixels](https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels).

#### Acknowledgements

Initial engineering work was supported by the Foundation of Psychocultural Research and Sherman Fairchild Award at Hampshire College. 

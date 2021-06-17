# Brain Observatory Toolbox
A MATLAB toolbox for **accessing and using** the neural recording public datasets from the **Allen Brain Observatory**[\[1\]](#references). 

:eyes: See the **Brain Observatory Toolbox** in action, with the [**EphysDemo**](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F501c4bc8-2509-40fc-aba0-323d33dff728%2Ffiles%2FEphysDemo.mlx&embed=web) and the [**OphysDemo**](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F501c4bc8-2509-40fc-aba0-323d33dff728%2Ffiles%2FOphysDemo.mlx&embed=web) demonstration live scripts.

:construction: The Brain Observatory Toolbox is at an early stage (v0.9), meaning two things:
* Questions, suggestions, and other feedback are highly welcomed (in the **[Discussion forum](https://github.com/emeyers/Brain-Observatory-Toolbox/discussions/118)**)
* Some interface compatibility changes may occur at each early-stage release (v0.9.x)
  * The Allen Brain Observatory dataset records, files, and values browsed and accessed by this toolbox would not be impacted. 

## About the Allen Brain Observatory datasets
[Data releases](https://portal.brain-map.org/latest-data-release) from the Allen Brain Observatory include two datasets of neural activity recordings: 

| Dataset | Recording Type | Nickname | Details |
| --- | --- | --- | --- |
| Visual Coding Neuropixels [\[2\]](#references) | Large-scale neural probe recordings | "ephys" (electrophysiology) | [details](https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels) |
| Visual Coding 2P [\[3\]](#references) | Two-photon calcium imaging | "ophys" (optical physiology) | [details](http://portal.brain-map.org/explore/circuits/visual-coding-2p) |

The Visual Coding datasets are both collected from the living mouse brain during presentation of varying visual stimuli. Technical white papers (see Details for each dataset) provide detailed information about the experimental technicalities and computational pipelines. 

## About the Brain Observatory Toolbox (BOT) 
 
The Brain Observatory Toolbox (BOT) provides a uniform interface to access and use these Visual Coding neural datasets. 

The BOT interface provides [tabular](https://www.mathworks.com/help/matlab/matlab_prog/access-data-in-a-table.html) representations of available dataset items and [object](https://www.mathworks.com/help/matlab/matlab_oop/operations-with-objects.html) representations of specific dataset items: 

![alt text](https://github.com/emeyers/Brain-Observatory-Toolbox/blob/backend/BOTDataSchematic.png?raw=true)

**Key Points:**
* Supported dataset items: experimental sessions (for both 2P and Neuropixels) as well as probes, channels, and units (for Neuropixels). 
* Tabular indexing or unique item identifiers allow specific item selection from item tables, for inspection and analysis as item objects.
* Item object [properties](https://www.mathworks.com/help/matlab/properties-storing-data-and-state.html) access direct, derived, and file-linked values for an item. 
* Values for item object properties involving extensive compute or file reading are computed "on demand". 
* Item object [methods](https://www.mathworks.com/help/matlab/methods-defining-operations.html?s_tid=CRUX_lftnav) allow computations of values determined with additional user-specified arguments. 
* The BOT provides local caching<sup>1</sup> to provide the fastest possible initial and repeat performance within and across MATLAB sessions.

<sup>1. For retrieved item information, object representations, and file contents</sup>

To preview the BOT in action: view the [Ephys Demo](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F6aee4c33-d05e-4715-82ab-748f121adcad%2Fd61de411-5e28-4eba-8c36-c8b1df0435fc%2Ffiles%2FEphysDemo.mlx&embed=web) and/or the [Ophys Demo](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F6aee4c33-d05e-4715-82ab-748f121adcad%2Fd61de411-5e28-4eba-8c36-c8b1df0435fc%2Ffiles%2FOphysDemo.mlx&embed=web).

## Installation Instructions

1. Download the `.zip` file from the latest GitHub release
2. Unzip via preferred system tool to desired local folder location
3. Open MATLAB 
4. Add root directory of the unzipped folder contents to the MATLAB path, in one of three ways: 
   1. Navigate to root directory in the *Current Folder* browser and select "Add to Path" from the right-click context menu<sup>1</sup>
   1. Open the *Set Path* dialog from the Environment section of the Home tab
   1. Call `addpath(<root directory location>)` in the Command Window
   
<sup>1. Use the "Selected Folders" option. The BOT is contained in the `+bot` [package folder](https://www.mathworks.com/help/matlab/matlab_oop/scoping-classes-with-packages.html). It is necessary and sufficient to add the package's parent folder to the path. </sup>

#### Required products
* MATLAB (R2021a)
* Image Processing Toolbox (if running the Visual Coding 2P demonstration `OphysDemo.mlx`)

## Getting started
Four MATLAB live scripts are provided to help get started: 

| Live Script(s) | About |
| --- | --- |
| `EphysDemo.mlx`<br>`OphysDemo.mlx` | Demonstrations of illustrative neurophysiological analyses using the BOT and the datasets| 
| `EphysTutorial.mlx`<br>`OphysTutorial.mlx` | Step-by-step instruction and "under the hood" technical detail about using the BOT and the datasets | 
 
 
Or to get a fast first look yourself, enter the following commands in MATLAB: 
```
>> sessions = bot.fetchSessions('ephys'); 
>> head(sessions) 
>> session = bot.session(sessions(1,:))
>> methods(session) 
```
----
#### References

[1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: [portal.brain-map.org/explore/circuits](http://portal.brain-map.org/explore/circuits).

[2] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels Dataset. Available from: [portal.brain-map.org/explore/circuits/visual-coding-neuropixels](https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels).

[3] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P Dataset. Available from: [portal.brain-map.org/explore/circuits/visual-coding-2p](http://portal.brain-map.org/explore/circuits/visual-coding-2p).

#### Acknowledgements

Initial engineering work was supported by the Foundation of Psychocultural Research and Sherman Fairchild Award at Hampshire College and hosted by the [Center for Brains, Minds, and Machines](https://cbmm.mit.edu/) at the Massachusetts Institute of Technology. 


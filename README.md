[![View Brain-Observatory-Toolbox on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/90900-brain-observatory-toolbox)

# Brain Observatory Toolbox
A MATLAB toolbox for accessing and using the neural recording public datasets from the **Allen Brain Observatory**[^1]. 

:rocket: Get started with the [**EphysQuickstart**](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F12bc63aa-aa55-48cc-8877-ea73b37dea59%2Ffiles%2FEphysQuickstart.mlx&embed=web) & [**OphysQuickstart**](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F12bc63aa-aa55-48cc-8877-ea73b37dea59%2Ffiles%2FOphysQuickstart.mlx&embed=web) guides.

:microscope: See the Brain Observatory Toolbox applied to neuroscience data analysis in the [**EphysDemo**](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F12bc63aa-aa55-48cc-8877-ea73b37dea59%2Ffiles%2Fdemos%2FEphysDemo.mlx&embed=web) & the [**OphysDemo**](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F12bc63aa-aa55-48cc-8877-ea73b37dea59%2Ffiles%2Fdemos%2FOphysDemo.mlx&embed=web).

:woman_teacher: Learn about how to use the Brain Observatory Toolbox with the [**EphysTutorial**](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F12bc63aa-aa55-48cc-8877-ea73b37dea59%2Ffiles%2Ftutorials%2FEphysTutorial.mlx&embed=web), [**OphysTutorial**](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F12bc63aa-aa55-48cc-8877-ea73b37dea59%2Ffiles%2Ftutorials%2FOphysTutorial.mlx&embed=web), & [**BehaviorTutorial**](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F12bc63aa-aa55-48cc-8877-ea73b37dea59%2Ffiles%2Ftutorials%2FBehaviorTutorial.mlx&embed=web).

:construction: The Brain Observatory Toolbox is at an early stage; the interface is not guaranteed stable across the v0.9.x releases. 

Questions, suggestions, and other feedback are highly welcomed (in the **[Discussion forum](https://github.com/emeyers/Brain-Observatory-Toolbox/discussions/118)**).

## About the Allen Brain Observatory datasets
[Data releases](https://portal.brain-map.org/latest-data-release) from the Allen Brain Observatory include two datasets of neural activity recordings: 

| Dataset | Recording Type | Nickname | Details |
| --- | --- | --- | --- |
| **Visual Coding Neuropixels** [^2] | Large-scale neural probe recordings | "ephys" (electrophysiology) | [details](https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels) |
| **Visual Coding 2P** [^3] | Two-photon calcium imaging | "ophys" (optical physiology) | [details](http://portal.brain-map.org/explore/circuits/visual-coding-2p) |

The Visual Coding datasets are both collected from the living mouse brain during presentation of varying visual stimuli. Technical white papers (see Details for each dataset) provide detailed information about the experimental technicalities and computational pipelines. 

## About the Brain Observatory Toolbox (BOT) 
 
The Brain Observatory Toolbox (BOT) provides a uniform interface to access and use the Visual Coding neural datasets. 

The BOT interface provides [tabular](https://www.mathworks.com/help/matlab/matlab_prog/access-data-in-a-table.html) representations of available dataset items and [object](https://www.mathworks.com/help/matlab/matlab_oop/operations-with-objects.html) representations of specific dataset items: 

![Schematic of BOT data items & workflow](https://user-images.githubusercontent.com/23032671/188445081-9971259e-a430-4036-a84b-bcd46c950a50.png)

### Key Concepts
* **Item tables** support all [tabular operations](https://www.mathworks.com/help/matlab/tables.html), including [**tabular indexing**](https://www.mathworks.com/help/matlab/matlab_prog/access-data-in-a-table.html) which enables specific dataset item selection for inspection and analysis as item objects
* **Item objects** consist of numerous [properties](https://www.mathworks.com/help/matlab/properties-storing-data-and-state.html) which each return direct, derived, or file-linked values about a specific item
  * Some item objects also have [methods](https://www.mathworks.com/help/matlab/methods-defining-operations.html?s_tid=CRUX_lftnav) to compute values requiring additional user-specified arguments 

The basic workflow is illustrated by three lines of code: 
```matlab
>> sessions = bot.fetchSessions('ephys')  % Obtain/view table showing available ephys session items
>> session = bot.session(sessions(1,:)) % Obtain/view object representing first available session item
>> methods(session) % Display methods (functions) available to access additional session item values
```
👉Try typing these three lines directly into the [MATLAB command window](https://www.mathworks.com/help/matlab/ref/commandwindow.html#:~:text=The%20Command%20Window%20is%20always,as%20the%20Editor%2C%20type%20commandwindow%20)

### Technical Details
* Local caching (of retrieved item information, object representation, and file contents) is implemented, to provide the fastest possible initial and repeat performance within and across MATLAB sessions.

## Installation

The easiest way to install the Brain Observatory Toolbox is to use the [**Add-on Explorer**](https://www.mathworks.com/products/matlab/add-on-explorer.html): 
1. Launch the Add-on Explorer ![image](https://user-images.githubusercontent.com/23032671/188336991-77ba49f1-d70d-4111-a265-3f9ba284bb8d.png)
2. Search for "Brain Observatory Toolbox"
3. Press the "Add" button. ![image](https://user-images.githubusercontent.com/23032671/188341517-6c2d372a-9eac-4aed-974a-a102880212da.png)

#### Required products
* MATLAB (R2021a)
* Image Processing Toolbox (if running the Visual Coding 2P demonstration `OphysDemo.mlx`)

----
### Acknowledgements 

Initial engineering work was supported by the Foundation of Psychocultural Research and Sherman Fairchild Award at Hampshire College and hosted by the [Center for Brains, Minds, and Machines](https://cbmm.mit.edu/) at the Massachusetts Institute of Technology. 


[^1]: Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: [portal.brain-map.org/explore/circuits](http://portal.brain-map.org/explore/circuits).

[^2]: Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels Dataset. Available from: [portal.brain-map.org/explore/circuits/visual-coding-neuropixels](https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels).

[^3]: Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P Dataset. Available from: [portal.brain-map.org/explore/circuits/visual-coding-2p](http://portal.brain-map.org/explore/circuits/visual-coding-2p).


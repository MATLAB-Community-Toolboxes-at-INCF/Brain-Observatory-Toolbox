[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=emeyers/Brain-Observatory-Toolbox&file=%2Bbot/%2binternal/README.mlx)  [![View Brain-Observatory-Toolbox on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/90900-brain-observatory-toolbox)

# Brain Observatory Toolbox
A MATLAB toolbox for accessing and using the neural recording public datasets from the **Allen Brain Observatory**[^1]. 

🗺️ Get oriented and get started with **3 lines of code**. You can:
* [**Open in MATLAB Online**](https://matlab.mathworks.com/open/github/v1?repo=emeyers/Brain-Observatory-Toolbox&file=%2Bbot/%2binternal/README.mlx)
* Enter `>>bot.README` on your own local/cloud [installation](#Installation)

This will orient you to several **live script examples** available to guide new users, including **_demos_** of neural data analysis & **_tutorials_** covering Brain Observatory Toolbox concepts & operations. You can also individually view (:eyes:) them or run (:arrow_forward:) these examples on MATLAB Online:
| Example Type | Data Type | View | Run | Data Type | View | Run | 
| --- | --- | --- | --- | --- | --- | --- |
| :rocket: Quickstart | Calcium Imaging (Ophys) | [:eyes:][OphysQuickstart] | [:arrow_forward:](https://matlab.mathworks.com/open/github/v1?repo=emeyers/Brain-Observatory-Toolbox&file=%2Bbot/quickstarts/OphysQuickstart.mlx) | Neuropixels Probe (Ephys) | [:eyes:][EphysQuickstart] | [:arrow_forward:](https://matlab.mathworks.com/open/github/v1?repo=emeyers/Brain-Observatory-Toolbox&file=%2Bbot/quickstarts/OphysQuickstart.mlx) |
| :microscope: Demo | Calcium Imaging (Ophys) | [:eyes:][OphysDemo] | [:arrow_forward:](https://matlab.mathworks.com/open/github/v1?repo=emeyers/Brain-Observatory-Toolbox&file=%2Bbot/quickstarts/OphysDemo.mlx) | Neuropixels Probe (Ephys)| [:eyes:][EphysDemo] | (\*) |
| :woman_teacher: Tutorial | Calcium Imaging (Ophys) | [:eyes:][OphysTutorial] | [:arrow_forward:](https://matlab.mathworks.com/open/github/v1?repo=emeyers/Brain-Observatory-Toolbox&file=%2Bbot/quickstarts/OphysTutorial.mlx) | Neuropixels Probe (Ephys) | [:eyes:][EphysTutorial] | (\*) | 

<sub>(\*) These data-intensive examples are currently recommended for use on local machinse or customer cloud instances only, not for MATLAB Online</sub>


[OphysQuickstart]: https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F3fa4ee4e-2d0d-476a-9593-01ab676c32bc%2Ffiles%2Fquickstarts%2FOphysQuickstart.mlx&embed=web
[EphysQuickstart]: https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F3fa4ee4e-2d0d-476a-9593-01ab676c32bc%2Ffiles%2Fquickstarts%2FEphysQuickstart.mlx&embed=web
[OphysDemo]: https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F3fa4ee4e-2d0d-476a-9593-01ab676c32bc%2Ffiles%2Fdemos%2FOphysDemo.mlx&embed=web
[EphysDemo]: https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F3fa4ee4e-2d0d-476a-9593-01ab676c32bc%2Ffiles%2Fdemos%2FEphysDemo.mlx&embed=web
[OphysTutorial]: https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F3fa4ee4e-2d0d-476a-9593-01ab676c32bc%2Ffiles%2Ftutorials%2FOphysTutorial.mlx&embed=web
[EphysTutorial]: https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F3fa4ee4e-2d0d-476a-9593-01ab676c32bc%2Ffiles%2Ftutorials%2FEphysTutorial.mlx&embed=web
[BehaviorTutorial]: https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F85a3255c-4ff5-42ef-9c10-b441318b4322%2F3fa4ee4e-2d0d-476a-9593-01ab676c32bc%2Ffiles%2Ftutorials%2FBehaviorTutorial.mlx&embed=web

:construction: The Brain Observatory Toolbox is at an early stage; the interface is not guaranteed stable across the v0.9.x releases. 

:speech_balloon:	Questions? Suggestions? Roadblocks? Code contributors are regularly monitoring user-posted [GitHub issues](https://github.com/emeyers/Brain-Observatory-Toolbox/issues) & the [File Exchange discussion](https://www.mathworks.com/matlabcentral/fileexchange/90900-brain-observatory-toolbox#discussions_tab). 

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

## Installation
The easiest way to install the Brain Observatory Toolbox is to use the [**Add-on Explorer**](https://www.mathworks.com/products/matlab/add-on-explorer.html): 
1. Launch the Add-on Explorer ![image](https://user-images.githubusercontent.com/23032671/188336991-77ba49f1-d70d-4111-a265-3f9ba284bb8d.png)
2. Search for "Brain Observatory Toolbox"
3. Press the "Add" button. ![image](https://user-images.githubusercontent.com/23032671/188341517-6c2d372a-9eac-4aed-974a-a102880212da.png)

#### Required products
* MATLAB (R2021a or later)
* Image Processing Toolbox (if running the Visual Coding 2P demonstration `OphysDemo.mlx`)

----
### Acknowledgements 

Initial engineering work was supported by the Foundation of Psychocultural Research and Sherman Fairchild Award at Hampshire College and hosted by the [Center for Brains, Minds, and Machines](https://cbmm.mit.edu/) at the Massachusetts Institute of Technology. 


[^1]: Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: [portal.brain-map.org/explore/circuits](http://portal.brain-map.org/explore/circuits).

[^2]: Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels Dataset. Available from: [portal.brain-map.org/explore/circuits/visual-coding-neuropixels](https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels).

[^3]: Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P Dataset. Available from: [portal.brain-map.org/explore/circuits/visual-coding-2p](http://portal.brain-map.org/explore/circuits/visual-coding-2p).


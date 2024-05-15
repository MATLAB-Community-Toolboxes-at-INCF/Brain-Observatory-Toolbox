[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=emeyers/Brain-Observatory-Toolbox&file=%2Bbot/%2Binternal/README.mlx)  [![View Brain-Observatory-Toolbox on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/90900-brain-observatory-toolbox)

# Brain Observatory Toolbox
A MATLAB toolbox for accessing and using the neural recording public datasets from the **Allen Brain Observatory**[^1]. 

## Getting Started 

### Quickstart examples for each Allen Brain Observatory dataset
[Data releases](https://portal.brain-map.org/latest-data-release) from the Allen Brain Observatory include four datasets of neural activity recordings during presentations of visual stimuli to awake mice. Quickstart examples for each can be viewed, and readily run in [MATLAB Online](https://www.mathworks.com/products/matlab-online.html): 

| Dataset | Recordings | Experiment | Details | Quickstart Example | 
| --- | --- | --- | --- | --- | 
| **Visual Coding 2P** [^2] | 🔬 "ophys"<sup>a</sup> | Passive<sup>c</sup> | [details](http://portal.brain-map.org/explore/circuits/visual-coding-2p) | [👀 (view)](https://www.mathworks.com/matlabcentral/fileexchange/90900-brain-observatory-toolbox)      [▶️ (run)](https://matlab.mathworks.com) |
| **Visual Coding Neuropixels** [^3] | ⚡ "ephys"<sup>b</sup>| Passive<sup>c</sup>| [details](https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels) |[👀 (view)](https://www.mathworks.com/matlabcentral/fileexchange/90900-brain-observatory-toolbox)    [▶️ (run)](https://matlab.mathworks.com) |
| **Visual Behavior 2P** [^4] | 🔬 "ophys"<sup>a</sup>| Active<sup>d</sup> | [details](http://portal.brain-map.org/explore/circuits/visual-behavior-2p) | [👀 (view)](https://www.mathworks.com/matlabcentral/fileexchange/90900-brain-observatory-toolbox)    [▶️ (run)](https://matlab.mathworks.com) |
| **Visual Behavior Neuropixels** [^5] |⚡ "ephys"<sup>b</sup> | Active<sup>d</sup> | [details](https://portal.brain-map.org/explore/circuits/visual-behavior-neuropixels) | (coming soon) | 

<sub><sup>a</sup> two-photon (2P) calcium imaging <sup>b</sup> large-scale neural probe recordings <sup>c</sup> presentation of various visual stimuli w/ untrained subjects <sup>d</sup> visual change detection task w/ trained subjects</sub>

Technical white papers (see **Details**) provide information about the experimental protocols and computational pipelines for each dataset. 

### Three lines of code
These three lines of code illustrate the core workflow of the Brain Observatory Toolbox to access neural data, which is common across all datasets: 
```
ophysSessionTable = bot.listSessions('VisualCoding', 'Ophys')
exampleSession = bot.getSessions( ophysSessionTable(1, :) )
dff = exampleSession.fluorescence_traces_dff
```
Here `listSessions` lists available _items_ (of type Session) from the Visual Coding 2P dataset and `getSessions` creates an object to interact with the first listed item allowing reterieval of the fully preprocessed fluorescence traces representing the neural recording data. For further explanation, see [Key Concepts](https://github.com/MATLAB-Community-Toolboxes-at-INCF/Brain-Observatory-Toolbox/edit/vijayiyer05-patch-2/README.md#key-concepts) and/or explore [tutorials](#tutorials-explaining-access-of-dataset-contents).  

## Going Further 
### Demonstrations illustrating neural data analysis 
Demonstration examples illustrate neural data analysis concepts and practice while using the Brain Observatory Toolbox: 

| Dataset | Demonstration Example | About |
| --- | --- | --- |
| **Visual Coding 2P** | [👀 (view)](https://www.mathworks.com/matlabcentral/fileexchange/90900-brain-observatory-toolbox)    [▶️ (run)](https://matlab.mathworks.com) | TODO |
| **Visual Coding Neuropixels** | [👀 (view)](https://www.mathworks.com/matlabcentral/fileexchange/90900-brain-observatory-toolbox)  (*) | TODO |    

<sub>(\*) These data-intensive examples are currently recommended for use on local machines or user-configured cloud instances only, not for MATLAB Online</sub>

### Tutorials explaining access of dataset contents 
Tutorial examples provide step-by-step guidance for using the Brain Observatory Toolbox to access and understand the metadata, processed data, and (where applicable) raw data available in the Allen Brain Observatory datasets: 

| Dataset | Demonstration Example | About |
| --- | --- | --- |
| **Visual Coding 2P** | [👀 (view)](https://www.mathworks.com/matlabcentral/fileexchange/90900-brain-observatory-toolbox)    [▶️ (run)](https://matlab.mathworks.com) | TODO |
| **Visual Coding Neuropixels** | [👀 (view)](https://www.mathworks.com/matlabcentral/fileexchange/90900-brain-observatory-toolbox)    (*) | TODO |

<sub>(\*) These data-intensive examples are currently recommended for use on local machines or user-configured cloud instances only, not for MATLAB Online</sub>

## Key concepts 

### Allen Brain Observatory dataset items
Allen Brain Observatory datasets each consist of various _items_ of types depending on the specific dataset: 
![Schematic of BOT data items & workflow](https://user-images.githubusercontent.com/23032671/224573702-01e92b8b-5a05-4f98-bdca-0bd58317f3c5.png)

### Brain Observatory Toolbox operations
The Brain Observatory Toolbox provides a set of two functions for each dataset item type: 
- `listXXX` functions returns a [table](https://www.mathworks.com/help/matlab/matlab_prog/access-data-in-a-table.html) of available items in the dataset
- `getXXX` functions returns an [object](https://www.mathworks.com/help/matlab/matlab_oop/operations-with-objects.html) of selected item(s) by id(s) or table row(s)

This uniform workflow (across datasets and item types) is illustrated here: 
![Schematic of BOT data items & workflow](https://user-images.githubusercontent.com/23032671/224573702-01e92b8b-5a05-4f98-bdca-0bd58317f3c5.png)

The dataset item's contents are exposed through the object's [properties](https://www.mathworks.com/help/matlab/properties-storing-data-and-state.html) and (where applicable) [methods](https://www.mathworks.com/help/matlab/properties-storing-data-and-state.html). For further guidance and explanation, see the [Tutorials](#tutorials-explaining-access-of-dataset-contents). 

## Installation
To install the Brain Observatory Toolbox persistently on a local machine or cloud instance, the [**Add-on Explorer**](https://www.mathworks.com/products/matlab/add-on-explorer.html) is recommended: 
1. Launch the Add-on Explorer ![image](https://user-images.githubusercontent.com/23032671/188336991-77ba49f1-d70d-4111-a265-3f9ba284bb8d.png)
2. Search for "Brain Observatory Toolbox"
3. Press the "Add" button. ![image](https://user-images.githubusercontent.com/23032671/188341517-6c2d372a-9eac-4aed-974a-a102880212da.png)

#### Required products
* MATLAB (R2023b or later)
* Image Processing Toolbox (if running the Visual Coding 2P demonstration `OphysDemo.mlx`)

----
### About the Brain Observatory Toolbox
:construction: The Brain Observatory Toolbox is at an early stage; the interface is not guaranteed stable across the v0.9.x releases. 

:speech_balloon:	Questions? Suggestions? Roadblocks? Code contributors are regularly monitoring user-posted [GitHub issues](https://github.com/emeyers/Brain-Observatory-Toolbox/issues) & the [File Exchange discussion](https://www.mathworks.com/matlabcentral/fileexchange/90900-brain-observatory-toolbox#discussions_tab). 

### Acknowledgements 

Initial engineering work, done by Ethan Meyers and Xinzhu Fang, was supported by the Foundation of Psychocultural Research and Sherman Fairchild Award at Hampshire College and hosted by the [Center for Brains, Minds, and Machines](https://cbmm.mit.edu/) at the Massachusetts Institute of Technology. 


[^1]: Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: [portal.brain-map.org/explore/circuits](http://portal.brain-map.org/explore/circuits).

[^2]: Dataset: Allen Institute MindScope Program (2016). Allen Brain Observatory -- 2-photon Visual Coding [dataset]. Available from [brain-map.org/explore/circuits](https://portal.brain-map.org/explore/circuits/visual-coding-2p). Primary publication: de Vries, S. E. J., Lecoq, J. A., Buice, M. A., et al. (2020). A large-scale standardized physiological survey reveals functional organization of the mouse visual cortex. Nature Neuroscience, 23, 138-151. [https://doi.org/10.1038/s41593-019-0550-9](https://doi.org/10.1038/s41593-019-0550-9)

[^3]: Dataset: Allen Institute MindScope Program (2019). Allen Brain Observatory -- Neuropixels Visual Coding [dataset]. Available from [brain-map.org/explore/circuits](https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels). Primary publication: Siegle, J. H., Jia, X., Durand, S., et al. (2021). Survey of spiking in the mouse visual system reveals functional hierarchy. Nature, 592(7612), 86-92. https://doi.org/10.1038/s41586-020-03171-x

[^4]: Dataset: Allen Institute MindScope Program (2021). Allen Brain Observatory -- 2-photon Visual Behavior [dataset]. Available from [brain-map.org/explore/circuits/visual-behavior-2p](https://portal.brain-map.org/explore/circuits/visual-coding-2p).

[^5]: Dataset: Allen Institute MindScope Program (2022). Allen Brain Observatory -- Neuropixels Visual Behavior [dataset].


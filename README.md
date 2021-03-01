# Brain-Observatory-Toolbox
A MATLAB toolbox for accessing and working with the Allen Brain Observatory \[1\] neural recording datasets

The Allen Brain Observatory resource  comprises extensive public datasets of neural activity in the mouse visual cortex during visual stimulus presentation. These datasets are based on cellular-scale experimental neural recordings conducted at the Allen Institute for Brain Science: 
* the Visual Coding – 2P dataset \[2\], based on two-photon calcium imaging
* the Visual Coding – Neuropixels dataset \[3\], based on large-scale electrophysiological probes

The Brain Observatory Toolbox (BOT) provides a uniform interface allowing users to conveniently access and work with these two experimental neural datasets.

The BOT interface provides:
* Retrieval of public Visual Coding dataset directories describing contents and metadata
* Tabular data operations to inspect and select dataset items
* Object interfaces to inspect individual dataset items and retrieve underlying experimental data
* Useful methods to assist in analysing neural responses and behavioural data 
* Caching of retrieved directories and data, for best possible initial and repeat performance

## Installation

1. Download the latest release as a `.zip` file.
1. Unzip using preferred system tool. 
1. Add the base directory of unzipped contents to the MATLAB path.  
<sup>Note it is unnecessary to add subdirectories to the MATLAB path; all contents of the `+bot` package are made available by adding the base directory</sup>

#### Optional requirements

Some aspects of the toolbox can make use of accelerated `.mex` files, which require a `mex` compiler to be configured in MATLAB. These files will be compiled automatically when needed. If a `mex` compiler is not configured, then MATLAB native versions will be used.

## Getting started

### Toolbox interface

The toolbox classes are contained within the `bot` namespace. Once the toolbox is added to the MATLAB path, you can access the data via the main factory functions:

`bot.fetchSessions()` — Retrieve a table of available EPhys or OPhys experimental sessions.

`bot.fetchExperiments()` — Retrieve a table of available OPhys experiments.

`bot.fetchProbes()` — Retrieve a table of individual probes used in the EPhys experiments.

`bot.fetchUnits()` — Retrieve a table of individual units (putative neurons) recorded in the EPhys experiments.

Analogous factory functions are used to obtain individual experiments or units, which can be manipulated to obtain experimental data:

`bot.session(session_id)` — Retrieve a single experimental session.

`bot.experiment(experiment_id)` — Retrieve a single experiment.

`bot.probe(probe_id)` — Retrieve a single experimental probe.

`bot.unit(unit_id)` — Retrieve a single experimental unit.

The toolbox manages downloading and caching of experimental data, in a "lazy access" fashion — only the minimal required data is downloaded.

### Example usage
See the [Ophys Quick Start Example](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F6aee4c33-d05e-4715-82ab-748f121adcad%2Ff8904f7a-8904-2deb-4404-99caae194d40%2Ffiles%2FOphysQuickStart.mlx&embed=web) for an illustration of how these toolbox classes enable retrieving, filtering, and acccessing the Visual Coding – 2P dataset [2] from the Allen Brain Observatory. See also the Ophys demo for a more detailed dive into analysis of the 2P dataset.

See the Ephys Quick Start Example and the Ephys Demo for examples of how to access, filter and analyse the electrophysiology data from the Visual Coding – Neuropixels dataset [3].

----
#### References

[1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: [portal.brain-map.org/explore/circuits](http://portal.brain-map.org/explore/circuits).

[2] Copyright 2016 Allen Institute for Brain Science. Visual Coding - 2P Dataset. Available from: [portal.brain-map.org/explore/circuits/visual-coding-2p](http://portal.brain-map.org/explore/circuits/visual-coding-2p).

[3] Copyright 2020 Allen Institute for Brain Science. Visual Coding – Neuropixels Dataset. Available from: [portal.brain-map.org/explore/circuits/visual-coding-neuropixels](https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels).

#### Acknowledgements

Core engineering work was supported by the Foundation of Psychocultural Research and Sherman Fairchild Award at Hampshire College. 

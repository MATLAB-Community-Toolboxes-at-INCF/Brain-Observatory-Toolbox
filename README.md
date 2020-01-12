# Brain-Observatory-Toolbox
A MATLAB toolbox for interacting with the Allen Brain Observatory datasets \[1\]. Currently the Visual Coding - 2P dataset \[2\] is supported, consisting of neural recordings based on two-photon calcium imaging.

The Brain Observatory Toolbox (BOT) enables users to conveniently work with the experimental neural datasets available from the Allen Brain Observatory. The BOT helps you search and filter the datasets; download and manage the data; and provides useful methods to assist in analysing neural responses and behavioural data.

## Installation

1. Clone the Brain Observatory Toolbox repository using `git`, or download a release as a `.zip` file.
2. Add the base directory to the MATLAB path. Note it is not needed to add the subdirectory `+bot` to the MATLAB path.

#### Optional requirements

Some aspects of the toolbox can make use of accelerated `.mex` files, which require a `mex` compiler to be configured in MATLAB. These files will be compiled automatically when needed. If a `mex` compiler is not configured, then MATLAB native versions will be used.

## Getting started

### Toolbox interface

The toolbox classes are contained within the `bot` namespace. Once the toolbox is added to the MATLAB path, you can access the three main classes:

`bot.sessionfilter` — Retrieve and manage lists of available experimental sessions, filtering them by various experimental parameters.

`bot.session` — Encapsulate, manage and access data for a single experimental season.

`bot.cache` — Internal class that manages caching of experimental data.

### Example usage
See the [Ophys Quick Start Example](https://www.mathworks.com/matlabcentral/fileexchange/66276-emeyers-brain-observatory-toolbox) for an illustration of how these toolbox classes enable retrieving, filtering, and acccessing the Visual Coding - 2P dataset from the Allen Brain Observatory.

#### References

[1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: [portal.brain-map.org/explore/circuits](http://portal.brain-map.org/explore/circuits).

[2] Copyright 2016 Allen Institute for Brain Science. Visual Coding - 2P Dataset. Available from: [portal.brain-map.org/explore/circuits/visual-coding-2p](http://portal.brain-map.org/explore/circuits/visual-coding-2p).

#### Acknowledgements

Core engineering work was supported by the Foundation of Psychocultural Research and Sherman Fairchild Award at Hampshire College. 

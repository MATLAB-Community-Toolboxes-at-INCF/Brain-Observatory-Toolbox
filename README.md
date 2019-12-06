# Brain-Observatory-Toolbox
A MATLAB toolbox for interacting with the [Allen Brain Observatory](http://observatory.brain-map.org/visualcoding)

## Installation

Clone the Brain Observatory Toolbox repository using `git`, or download a release as a `.zip` file. Add the base directory to the `matlab` path; *do not* add the directory `+bot` to the matlab path.

#### Additional requirements

Some aspects of the toolbox make use of accelerated `.mex` files, and therefore require `mex` to be configured. These files will be compiled automatically when needed; if `mex` is not available, then `matlab` native versions will be used.

#### Privacy information

We track the usage of this toolbox along with some demographics using the Google Analytics API, for us to understand the demand for the toolbox.

## Getting started

### Toolbox interface
The toolbox classes are contained within the `bot` namespace within MATLAB. Once the toolbox is added to the `matlab` path, you can access the main classes:

`bot.sessionfilter` — Retrieve and manage lists of available experimental sessions, filtering them by various experimental parameters.

`bot.session` — Encapsulate, manage and access data for a single experimental season.

`bot.cache` — Internal class that manages caching of experimental data.

### Example usage
To see how the toolbox enables retrieving, filtering, and acccessing the Allen Brain Observatory dataset, see the [Ophys Quick Start Example](https://www.mathworks.com/matlabcentral/fileexchange/66276-emeyers-brain-observatory-toolbox). 

#### Acknowledgements

All data accessed by this toolbox comes from the Allen Brain Observatory © 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: http://observatory.brain-map.org/visualcoding

This engineering work was supported by the Foundation of Psychocultural Research and Sherman Fairchild Award at Hampshire College. We are also grateful to MathWorks for their advice.

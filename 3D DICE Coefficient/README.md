# Table of contents

- [Usage](#usage)
- [Installation](#installation)
- [Recommended configurations](#recommended-configurations)
- [Contributing](#contributing)
- [License](#license)

# Usage

[(Back to top)](#table-of-contents)

This code can be used to calculate the 3D DICE coefficient between two meshes.
Both meshes should come from seperate STL files (file extension '.stl').
The ground truth mesh should be titled 'Ground Truth Mesh.stl'.
The Predicted mesh should be titled 'Predicted Mesh.stl'.

3D DICE coefficient can be used to compare the agreement between two geometries.
The coefficient is defined as two times the volume intersection between the two meshes, divided by the total volume of both meshes.
The obtain volumes, the meshes are converted into voxel arrays.

# Installation

[(Back to top)](#table-of-contents)

1. Install MATLAB R2022b or more recent release (code will likely run on older versions, although it has not been tested).
2. [Download](https://www.mathworks.com/downloads/) latest MATLAB release.
3. Install the `pde_toolbox` add-on during installation along with the recommended add-ons. This can be installed after download via 'Add-on Explorer'
6. Have a look at [Recommended configurations](#recommended-configurations).

# Recommended configurations

[(Back to top)](#table-of-contents)

Within the MATLAB environment set the following preferences:

```sh
Home > Preferences > Workspace > Maximum array size: 10000
```
```sh
Home > Preferences > Workspace > Maximum struct/object nesting level: 200
```
```sh
Home > Preferences > Workspace > MATLAB array size limit: 100%
```

# License

[Download](https://www.mathworks.com/license/mll/license.txt) the MATLAB licensing agreement.

The work contained within this repository is considered property of OpSens Medical.

[OpsensMedical/OptoFlow](https://github.com/OpsensMedical/OptoFlow).

# Author Details

[(Back to top)](#table-of-contents)

Name: Stewart McLennan (SMC)
Date: 2023-03-07
Company: Opsens Medical
Position: R&D Engineer - Architecture and Data Processing







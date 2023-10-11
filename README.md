# SIRI (Service Interface for Real-time Information)
## Overview

- SIRI (Service Interface for Real-Time Information) XML schema is a standardized format for exchanging real-time information about public transportation services and events.

## Folder Structure 📁

More information on the folders' structure can be found in the [wiki](https://github.com/TuThoThai/SIRI/wiki/Structure-%26-Compatibility/#folders)

## UML model 

- You can refer to the SIRI UML model for a detailed UML view of the schema packages.
- The SIRI UML model is available in electronic format.

## Getting Started 🚀
### Main Root Schemas

**siri.xsd**

- Defines the SIRI XML model elements and attributes that are used to exchange public transport information.
- Supports both request/response and publish/subscribe communication patterns.
- Used by a wide range of public transport operators and service providers.

**siri_all_functionalServices.xsd**

- Imports all of the SIRI functional service schemas.
- Provides a convenient way to access all of the SIRI functionality in a single schema.
- Can be used to develop applications that support all SIRI services.

**siriSg.xsd**

- Defines supplementary SIRI XML model elements and attributes that are used by some SIRI services.
- For example, the siriSg.xsd schema defines elements for exchanging vehicle location and status information, as well as stop monitoring information.
- Can be used to develop applications that support advanced SIRI features.

### XML Examples

- Explore XML examples in the */examples* subdirectory.

Further information on the examples is available on the [wiki](https://github.com/TuThoThai/SIRI/wiki/Using-SIRI#how-to-use-example-files)

### Support for XML Editors 

- **Altova XMLSpy Project**: Find an organized view of the schema and examples in the root directory.
  - Project file: Siri.spp
- **Oxygen Project File:**
  - Project file: Siri.xpr

More information on the tools available for working with SIRI XML schema can be found in the [wiki](https://github.com/TuThoThai/SIRI/wiki/Software-&-tools)

## Releases

| Release Number | Release Date | Summary of Changes         |
|----------------|--------------|----------------------------|
| v2.1           | 2022.10.25   | [Latest](https://github.com/SIRI-CEN/SIRI/releases/tag/v2.1) |
| v2.0           | 2015.05.13   | Bug fixes and updates      |
| v1.4a          | 2011-04-18   | Minor corrections          |
| v1.3           | 2009-03-31   | Corrections and revisions  |

Changes to the SIRI schema up to version 2.0 since v1.3 are available in [release-notes](release-notes) folder

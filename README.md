# SIRI (Service Interface for Real-time Information)
## Overview

- SIRI (Service Interface for Real-Time Information) XML schema is a standardized format for exchanging real-time information about public transportation services and events.

## Folder structure 📁

More information on the folders' structure can be found in the [wiki](https://github.com/ITxPT/SIRI/wiki/Structure-%26-Compatibility/#folders)

## UML model 

- You can refer to the SIRI UML model for a detailed UML view of the schema packages.
- The SIRI UML model is available in electronic format.

## Getting started 🚀
### Main Root Schemas

**siri.xsd**

- Defines the SIRI XML model elements and attributes that are used to exchange public transport information.
- Supports both request/response and publish/subscribe communication patterns.
- Used by a wide range of public transport operators and service providers.

**siri_all_functionalServices.xsd**

- Imports all the SIRI functional service schemas.
- Provides a convenient way to access all the SIRI functionality in a single schema.
- Can be used to develop applications that support all SIRI services.

**siriSg.xsd**

- Defines additional SIRI XML model elements and attributes that are used by some SIRI services.
- For example, the siriSg.xsd schema defines elements for exchanging vehicle location and status information, as well as stop monitoring information.
- Can be used to develop applications that support advanced SIRI features.

### XML examples

- Explore XML examples in the */examples* subdirectory.

Further information on the examples is available on the [wiki](https://github.com/ITxPT/SIRI/wiki/Using-SIRI#how-to-use-example-files)

### Support for XML editors 

- **Altova XMLSpy Project**: Find an organized view of the schema and examples in the root directory.
  - Project file: Siri.spp
- **Oxygen Project File:**
  - Project file: Siri.xpr

More information on the tools available for working with SIRI XML schema can be found in the [wiki](https://github.com/ITxPT/SIRI/wiki/Software-&-tools)

## Releases

| Release Number | Release Date | Summary of Changes         |
|----------------|--------------|----------------------------|
| v2.1           | Oct 2002   | [Latest](https://github.com/SIRI-CEN/SIRI/releases/tag/v2.1) |
| v2.0           | May 2015   | Bug fixes and updates      |
| v1.4a          | April 2011   | Minor corrections          |
| v1.3           | March 2009   | Corrections and revisions  |

Changes to the SIRI schema from v1.3 and up to v2.0 are available in [release-notes](release-notes) folder

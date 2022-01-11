# bifrost
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.?.?] - 2022-01-11
### Added
- `-Clean` now deletes files matching the `*.orig` filter left over when mergetool.keepBackup is true
- `-Branch BRANCHNAME -SetUpstreamOrigin` now prompts the user for confirmation before pushing, in order to prevent pushing unwanted commits

## [0.0.0] - 2021-09-07
### Added
- Ability to invoke `-DotnetConfig` to specify a nuget config file for dotnet restore
- Added CHANGELOG

### Changed
- Non-op changes to internal padding code. Needs to be refactored.
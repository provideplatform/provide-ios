fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios test
```
fastlane ios test
```
Runs all the tests
### ios beta
```
fastlane ios beta
```
Submit a new Beta Build to Apple TestFlight

This will also make sure the profile is up to date
### ios release
```
fastlane ios release
```
Deploy a new version to the App Store
### ios unicorn_beta
```
fastlane ios unicorn_beta
```
Submit unicorn beta to TestFlight
### ios unicorn_driver_beta
```
fastlane ios unicorn_driver_beta
```
Submit unicorn driver beta to TestFlight
### ios carmony_beta
```
fastlane ios carmony_beta
```
Submit carmony beta to TestFlight
### ios arcade_city_beta
```
fastlane ios arcade_city_beta
```
Submit arcade city beta to TestFlight

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

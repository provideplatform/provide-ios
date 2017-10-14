# Provide iOS

## Setup Instructions
1. Clone the project: `git clone git@bitbucket.org:provide/provide-ios.git`
2. Run: `git submodule --init` to checkout the `KTSwiftExtensions` submodule. This is setup as a local pod for ease of development.
3. Run: `bundle install`
4. Run: `pod install`


## Useful Settings

### Show build duration in Xcode:
- `defaults write com.apple.dt.Xcode ShowBuildOperationDuration -bool YES` (Use Command + B to see it in the Xcode status bar at the top)

### Trim Whitespace
- Preferences > Text Editing > While Editing: Checkmark: Automatically trim trailing whitespace & Including whitespace-only lines

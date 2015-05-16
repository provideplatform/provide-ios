### Purpose:
#
# Sets the build number to the git revision number.
#     This helps with keeping versions distinct in TestFlight, Craslhytics, HockeyApp.
# Sets the current git commit SHA in the app, including marking if it is dirty.
#     This helps with traceability.
# Sets the time of the build to the concise month, day, hour.
#     This makes checking for the freshness of a build more human-friendly.

### Set up:
#
# Enable "Preprocess Info.plist File" (INFOPLIST_PREPROCESS) in the primary target's
# Build Settings (under the "Packaging" section, with 'All' settings visible).
#
# Set "Info.plist Preprocessor Prefix File" (INFOPLIST_PREFIX_HEADER) to InfoPlist.h.
#
# Add InfoPlist.h to the project's git ignore file (it is generated here).
#
# Add a new target with a Build Phases - Run Script of "${PROJECT_DIR}/scripts/version-build.sh".
#
# Add the new target as a dependency of the primary build target.
#
# Add X_BUILD_NUMBER and/or X_GIT_HASH as values to your ${PROJECT_NAME}-Info.plist.
#
# This is being used with VersionHelper.swift for display in the UI.

# Refresh local git status
git fetch origin --unshallow --no-tags -q > /dev/null 2>&1

# Get dynamic values
revNumber=$(echo `git rev-list HEAD | wc -l`) # the echo trims leading whitespace
gitHash=`git rev-parse --short HEAD`
buildTime=$(date '+%m/%d/%y')
echo buildTime = "$buildTime", revNumber = "$revNumber", gitHash = "$gitHash"

# Write to InfoPlist.h
# Using this git-ignored file vs. direct Plist modification via PListBuddy avoids git changes.
echo "#define X_BUILD_NUMBER	$revNumber" > "${SRCROOT}/${PROJECT_NAME}/InfoPlist.h";
echo "#define X_BUILD_TIME	$buildTime" >> "${SRCROOT}/${PROJECT_NAME}/InfoPlist.h";
echo "$(echo `git status` | grep "nothing to commit" > /dev/null 2>&1; \
if [ "$?" -eq "0" ]; then \
	echo "#define X_GIT_HASH	$gitHash" >> "${SRCROOT}/${PROJECT_NAME}/InfoPlist.h";
else \
	echo "#define X_GIT_HASH	$gitHash-dirty" >> "${SRCROOT}/${PROJECT_NAME}/InfoPlist.h";
fi )";

# Let Xcode know the PList has changed.
# Prevent executing this line outside of Xcode (without proper set up).
if [ "$PROJECT_NAME" ]
then
	touch "${SRCROOT}/${PROJECT_NAME}/Info.plist"
fi

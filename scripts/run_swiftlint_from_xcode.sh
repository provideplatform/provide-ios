SCRIPT_LOCATION='/usr/local/bin/swiftlint'

VIOLATIONS_TO_IGNORE="\
Length|\
Force Cast|\
Name Format|\
TODO or FIXME"

if [ -e $SCRIPT_LOCATION ] ; then
    $SCRIPT_LOCATION | grep -Ev "($VIOLATIONS_TO_IGNORE) Violation"
else
    echo "error: $SCRIPT_LOCATION not found. Please run: brew update && brew install swiftlint"
    exit 1
fi

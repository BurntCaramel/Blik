#!/bin/sh

function print_usage
{
    echo "USAGE: *script* [-kit_path <path_to_DevMateKit>] [-app_name <application_name>] [-sign_ident <code_sign_identity>]"
}

KIT_PATH=""
APP_NAME=""
SING_IDENT=""
while test $# -gt 0; do
    case "$1" in
        -h|--help)
            print_usage
            exit 0
            ;;
        -kit_path)
            shift
            if test $# -gt 0; then
                KIT_PATH="$1"
            fi
            shift
            ;;
        -app_name)
            shift
            if test $# -gt 0; then
                APP_NAME="$1"
            fi
            shift
            ;;
        -sign_ident)
            shift
            if test $# -gt 0; then
                SIGN_IDENT="$1"
            fi
            shift
            ;;
        *)
            echo "Unknown input parameter \"$1\""
            break
            ;;
    esac
done

# try to get CODE_SIGN_IDENTITY from Xcode env and exit if fails
if [ -z "${SIGN_IDENT}" ]; then
    SIGN_IDENT="${CODE_SIGN_IDENTITY}"
    if [ -z "${SIGN_IDENT}" ]; then
        echo "Code sign identity is absent. Please provide one for correct work."
        print_usage
        exit 1
    fi
fi

# try to get DevMateKit framework path and exit if fails
if [ -z "${KIT_PATH}" ]; then
    APP_BUILD_DIR="${TARGET_BUILD_DIR}"
    APP_FRAMEWORKS_DIR="${FRAMEWORKS_FOLDER_PATH}"
    if [ -z "${APP_BUILD_DIR}" -o -z "$APP_FRAMEWORKS_DIR" ]; then
        echo "Could not find path to DevMateKit.framework. Please, provide the correct one."
        print_usage
        exit 2
    fi

    KIT_PATH="${APP_BUILD_DIR}/${APP_FRAMEWORKS_DIR}/DevMateKit.framework"
fi

# try to get main product name
if [ -z "${APP_NAME}" ]; then
    APP_NAME="${PRODUCT_NAME}"
    if [ -z "${APP_NAME}" ]; then
        APP_NAME=`uuidgen`
    fi
fi

KIT_VERSION_PATH="${KIT_PATH}/Versions/A"
REPORTER_APP="${KIT_VERSION_PATH}/Resources/Problem Reporter Sandboxed.app"
if [ ! -e "${REPORTER_APP}" ]; then
    echo "Could not find 'Problem Reporter Sandboxed.app' inside DevMateKit.framework. Please check framework integrity or provide correct path to it."
    print_usage
    exit 3
fi

REPORTER_PLIST="${REPORTER_APP}/Contents/Info.plist"
REPORTER_ENTITLEMENTS="${REPORTER_APP}/Contents/Resources/archived-expanded-entitlements.xcent"

# correct APP_NAME if needs (replace all '.', '_', ' ', '\', '/' with '-')
APP_NAME=${APP_NAME//[._ \\\/]/-}
OLD_BUNDLE_ID="com.devmate.Problem-Reporter-Sandboxed"
NEW_BUNDLE_ID="${OLD_BUNDLE_ID}.${APP_NAME}"
RESULT=0
while true; do
    defaults write "${REPORTER_PLIST}" CFBundleIdentifier -string "${NEW_BUNDLE_ID}"
    RESULT=$?
    if [ $RESULT != 0 ]; then
        break
    fi

    codesign -fv -s "${SIGN_IDENT}" --entitlements "${REPORTER_ENTITLEMENTS}" "${REPORTER_APP}"
    RESULT=$?
    if [ $RESULT != 0 ]; then
        break
    fi

    codesign -fv -s "${SIGN_IDENT}" "${KIT_VERSION_PATH}"
    RESULT=$?
    break
done

if [ $RESULT != 0 ]; then
    defaults write "${REPORTER_PLIST}" CFBundleIdentifier -string "${OLD_BUNDLE_ID}"
fi

exit $RESULT

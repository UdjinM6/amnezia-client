set(CPACK_COMPONENTS_ALL AmneziaVPN)

if (CPACK_GENERATOR STREQUAL productbuild)
    list(APPEND CPACK_COMPONENTS_ALL Uninstall)
endif()

if(NOT CODESIGN_INSTALLER_SIGNATURE)
    set(CODESIGN_INSTALLER_SIGNATURE    "$ENV{CODESIGN_INSTALLER_SIGNATURE}")
endif()

if(NOT CODESIGN_INSTALLER_KEYCHAIN)
    set(CODESIGN_INSTALLER_KEYCHAIN     "$ENV{CODESIGN_INSTALLER_KEYCHAIN}")
endif()

# A signing keychain is only ever set up for a build that is meant to be signed,
# so an identity missing at that point is a misconfigured secret. Fail loudly
# rather than quietly shipping an unsigned installer.
if(CODESIGN_INSTALLER_KEYCHAIN AND NOT CODESIGN_INSTALLER_SIGNATURE)
    message(FATAL_ERROR
        "CODESIGN_INSTALLER_KEYCHAIN is set but CODESIGN_INSTALLER_SIGNATURE is empty. "
        "Refusing to build an unsigned installer for a signed build.")
endif()

# Builds with neither set (forks, local builds) are packaged unsigned. Setting
# the keychain path alone would make CPack run pkgbuild with --sign "", which fails.
if(CODESIGN_INSTALLER_SIGNATURE)
    set(CPACK_PRODUCTBUILD_IDENTITY_NAME    "${CODESIGN_INSTALLER_SIGNATURE}")
    set(CPACK_PKGBUILD_IDENTITY_NAME        "${CODESIGN_INSTALLER_SIGNATURE}")
    set(CPACK_PRODUCTBUILD_KEYCHAIN_PATH    "${CODESIGN_INSTALLER_KEYCHAIN}")
    set(CPACK_PKGBUILD_KEYCHAIN_PATH        "${CODESIGN_INSTALLER_KEYCHAIN}")
endif()
